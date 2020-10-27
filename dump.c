/*
 * dump.c
 *
 * Copyright (c) 2009-2020, NIPPON TELEGRAPH AND TELEPHONE CORPORATION
 * Portions Copyright (c) 1996-2013, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 */
#include "postgres.h"

#include "libpq/pqformat.h"
#include "utils/array.h"
#include "utils/builtins.h"
#include "utils/lsyscache.h"
#include "utils/memutils.h"
#if PG_VERSION_NUM >= 90300
#include "access/tupmacs.h"
#endif



PG_FUNCTION_INFO_V1(dbms_stats_array_recv);

extern Datum dbms_stats_array_recv(PG_FUNCTION_ARGS);

static void ReadArrayBinary(StringInfo buf, int nitems,
				FmgrInfo *receiveproc, Oid typioparam, int32 typmod,
				int typlen, bool typbyval, char typalign,
				Datum *values, bool *nulls,
				bool *hasnulls, int32 *nbytes);
static void CopyAnyArrayEls(ArrayType *array,
			 Datum *values, bool *nulls, int nitems,
			 int typlen, bool typbyval, char typalign,
			 bool freedata);
static int ArrayCastAndSet(Datum src,
				int typlen, bool typbyval, char typalign,
				char *dest);

/*
 * recv function for use-defined type dbms_stats.anyarray.  Receive string
 * representation of anyarray object, and convert it into binary data.
 */
Datum
dbms_stats_array_recv(PG_FUNCTION_ARGS)
{
	StringInfo	buf = (StringInfo) PG_GETARG_POINTER(0);
	Oid			element_type;
	int			typlen;
	bool		typbyval;
	char		typalign;
	Oid			typioparam;
	int			i,
				nitems;
	Datum	   *dataPtr;
	bool	   *nullsPtr;
	bool		hasnulls;
	int32		nbytes;
	int32		dataoffset;
	ArrayType  *retval;
	int			ndim,
				flags,
				dim[MAXDIM],
				lBound[MAXDIM];
	ArrayMetaState *my_extra;

	/* Get the array header information */
	ndim = pq_getmsgint(buf, 4);
	if (ndim < 0)				/* we do allow zero-dimension arrays */
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_BINARY_REPRESENTATION),
				 errmsg("invalid number of dimensions: %d", ndim)));
	if (ndim > MAXDIM)
		ereport(ERROR,
				(errcode(ERRCODE_PROGRAM_LIMIT_EXCEEDED),
				 errmsg("number of array dimensions (%d) exceeds the maximum allowed (%d)",
						ndim, MAXDIM)));

	flags = pq_getmsgint(buf, 4);
	if (flags != 0 && flags != 1)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_BINARY_REPRESENTATION),
				 errmsg("invalid array flags")));

	element_type = pq_getmsgint(buf, sizeof(Oid));

	for (i = 0; i < ndim; i++)
	{
		int ub;

		dim[i] = pq_getmsgint(buf, 4);
		lBound[i] = pq_getmsgint(buf, 4);

		ub = lBound[i] + dim[i] - 1;
		/* overflow? */
		if (lBound[i] > ub)
			ereport(ERROR,
					(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
					 errmsg("integer out of range")));
	}

	/* This checks for overflow of array dimensions */
	nitems = ArrayGetNItems(ndim, dim);

	/*
	 * We arrange to look up info about element type, including its receive
	 * conversion proc, only once per series of calls, assuming the element
	 * type doesn't change underneath us.
	 */
	my_extra = (ArrayMetaState *) fcinfo->flinfo->fn_extra;
	if (my_extra == NULL)
	{
		fcinfo->flinfo->fn_extra = MemoryContextAlloc(fcinfo->flinfo->fn_mcxt,
													  sizeof(ArrayMetaState));
		my_extra = (ArrayMetaState *) fcinfo->flinfo->fn_extra;
		my_extra->element_type = ~element_type;
	}

	if (my_extra->element_type != element_type)
	{
		/* Get info about element type, including its receive proc */
		get_type_io_data(element_type, IOFunc_receive,
						 &my_extra->typlen, &my_extra->typbyval,
						 &my_extra->typalign, &my_extra->typdelim,
						 &my_extra->typioparam, &my_extra->typiofunc);
		if (!OidIsValid(my_extra->typiofunc))
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_FUNCTION),
					 errmsg("no binary input function available for type \"%s\"",
							format_type_be(element_type))));
		fmgr_info_cxt(my_extra->typiofunc, &my_extra->proc,
					  fcinfo->flinfo->fn_mcxt);
		my_extra->element_type = element_type;
	}

	if (nitems == 0)
	{
		/* Return empty array ... but not till we've validated element_type */
		PG_RETURN_ARRAYTYPE_P(construct_empty_array(element_type));
	}

	typlen = my_extra->typlen;
	typbyval = my_extra->typbyval;
	typalign = my_extra->typalign;
	typioparam = my_extra->typioparam;

	dataPtr = (Datum *) palloc(nitems * sizeof(Datum));
	nullsPtr = (bool *) palloc(nitems * sizeof(bool));
	ReadArrayBinary(buf, nitems,
					&my_extra->proc, typioparam, 0,
					typlen, typbyval, typalign,
					dataPtr, nullsPtr,
					&hasnulls, &nbytes);
	if (hasnulls)
	{
		dataoffset = ARR_OVERHEAD_WITHNULLS(ndim, nitems);
		nbytes += dataoffset;
	}
	else
	{
		dataoffset = 0;			/* marker for no null bitmap */
		nbytes += ARR_OVERHEAD_NONULLS(ndim);
	}
	retval = (ArrayType *) palloc(nbytes);
	SET_VARSIZE(retval, nbytes);
	retval->ndim = ndim;
	retval->dataoffset = dataoffset;
	retval->elemtype = element_type;
	memcpy(ARR_DIMS(retval), dim, ndim * sizeof(int));
	memcpy(ARR_LBOUND(retval), lBound, ndim * sizeof(int));

	CopyAnyArrayEls(retval,
					dataPtr, nullsPtr, nitems,
					typlen, typbyval, typalign,
					true);

	pfree(dataPtr);
	pfree(nullsPtr);

	PG_RETURN_ARRAYTYPE_P(retval);
}

static void
ReadArrayBinary(StringInfo buf,
				int nitems,
				FmgrInfo *receiveproc,
				Oid typioparam,
				int32 typmod,
				int typlen,
				bool typbyval,
				char typalign,
				Datum *values,
				bool *nulls,
				bool *hasnulls,
				int32 *nbytes)
{
	int			i;
	bool		hasnull;
	int32		totbytes;

	for (i = 0; i < nitems; i++)
	{
		int			itemlen;
		StringInfoData elem_buf;
		char		csave;

		/* Get and check the item length */
		itemlen = pq_getmsgint(buf, 4);
		if (itemlen < -1 || itemlen > (buf->len - buf->cursor))
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_BINARY_REPRESENTATION),
					 errmsg("insufficient data left in message")));

		if (itemlen == -1)
		{
			/* -1 length means NULL */
			values[i] = ReceiveFunctionCall(receiveproc, NULL,
											typioparam, typmod);
			nulls[i] = true;
			continue;
		}

		/*
		 * Rather than copying data around, we just set up a phony StringInfo
		 * pointing to the correct portion of the input buffer. We assume we
		 * can scribble on the input buffer so as to maintain the convention
		 * that StringInfos have a trailing null.
		 */
		elem_buf.data = &buf->data[buf->cursor];
		elem_buf.maxlen = itemlen + 1;
		elem_buf.len = itemlen;
		elem_buf.cursor = 0;

		buf->cursor += itemlen;

		csave = buf->data[buf->cursor];
		buf->data[buf->cursor] = '\0';

		/* Now call the element's receiveproc */
		values[i] = ReceiveFunctionCall(receiveproc, &elem_buf,
										typioparam, typmod);
		nulls[i] = false;

		/* Trouble if it didn't eat the whole buffer */
		if (elem_buf.cursor != itemlen)
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_BINARY_REPRESENTATION),
					 errmsg("improper binary format in array element %d",
							i + 1)));

		buf->data[buf->cursor] = csave;
	}

	/*
	 * Check for nulls, compute total data space needed
	 */
	hasnull = false;
	totbytes = 0;
	for (i = 0; i < nitems; i++)
	{
		if (nulls[i])
			hasnull = true;
		else
		{
			/* let's just make sure data is not toasted */
			if (typlen == -1)
				values[i] = PointerGetDatum(PG_DETOAST_DATUM(values[i]));
			totbytes = att_addlength_datum(totbytes, typlen, values[i]);
			totbytes = att_align_nominal(totbytes, typalign);
			/* check for overflow of total request */
			if (!AllocSizeIsValid(totbytes))
				ereport(ERROR,
						(errcode(ERRCODE_PROGRAM_LIMIT_EXCEEDED),
						 errmsg("array size exceeds the maximum allowed (%d)",
								(int) MaxAllocSize)));
		}
	}
	*hasnulls = hasnull;
	*nbytes = totbytes;
}

static void
CopyAnyArrayEls(ArrayType *array,
				Datum *values,
				bool *nulls,
				int nitems,
				int typlen,
				bool typbyval,
				char typalign,
				bool freedata)
{
	char	   *p = ARR_DATA_PTR(array);
	bits8	   *bitmap = ARR_NULLBITMAP(array);
	int			bitval = 0;
	int			bitmask = 1;
	int			i;

	if (typbyval)
		freedata = false;

	for (i = 0; i < nitems; i++)
	{
		if (nulls && nulls[i])
		{
			if (!bitmap)		/* shouldn't happen */
				elog(ERROR, "null array element where not supported");
			/* bitmap bit stays 0 */
		}
		else
		{
			bitval |= bitmask;
			p += ArrayCastAndSet(values[i], typlen, typbyval, typalign, p);
			if (freedata)
				pfree(DatumGetPointer(values[i]));
		}
		if (bitmap)
		{
			bitmask <<= 1;
			if (bitmask == 0x100)
			{
				*bitmap++ = bitval;
				bitval = 0;
				bitmask = 1;
			}
		}
	}

	if (bitmap && bitmask != 1)
		*bitmap = bitval;
}

static int
ArrayCastAndSet(Datum src,
				int typlen,
				bool typbyval,
				char typalign,
				char *dest)
{
	int			inc;

	if (typlen > 0)
	{
		if (typbyval)
			store_att_byval(dest, src, typlen);
		else
			memmove(dest, DatumGetPointer(src), typlen);
		inc = att_align_nominal(typlen, typalign);
	}
	else
	{
		Assert(!typbyval);
		inc = att_addlength_datum(0, typlen, src);
		memmove(dest, DatumGetPointer(src), inc);
		inc = att_align_nominal(inc, typalign);
	}

	return inc;
}

#ifdef UNIT_TEST
void test_dump(int *passed, int *total);
/*
 * Unit test entry point for dump.c.  This will be called by PG_init()
 * function, after initialization for this extension is completed .
 * This funciton should add the numbers of tests passed and the total number of
 * tests to parameter passed and total respectively.
 */
void
test_dump(int *passed, int *total)
{
	int local_passed = 0;
	int local_total = 0;

	elog(WARNING, "==========");

	/* Do tests here */

	elog(WARNING, "%s %d/%d passed", __FUNCTION__, local_passed, local_total);
	*passed += local_passed;
	*total += local_total;
}
#endif
