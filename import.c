/*
 * import.c
 *
 * Copyright (c) 2012-2018, NIPPON TELEGRAPH AND TELEPHONE CORPORATION
 */
#include "postgres.h"

#include "access/xact.h"
#include "catalog/namespace.h"
#include "catalog/pg_type.h"
#include "commands/copy.h"
#include "executor/spi.h"
#include "libpq/pqformat.h"
#include "mb/pg_wchar.h"
#include "tcop/tcopprot.h"
#include "utils/builtins.h"
#include "utils/lsyscache.h"
#include "utils/syscache.h"
#include "catalog/pg_class.h"
#if PG_VERSION_NUM >= 90300
#include "access/htup_details.h"
#endif

#include "pg_dbms_stats.h"

#define RELATION_PARAM_NUM	9

extern PGDLLIMPORT bool standard_conforming_strings;

PG_FUNCTION_INFO_V1(dbms_stats_import);

Datum	dbms_stats_import(PG_FUNCTION_ARGS);

static void get_args(FunctionCallInfo fcinfo, char **nspname, char **relname,
				char **attname, char **filename);
static void spi_exec_utility(const char *query);
static void spi_exec_query(const char *query, int nargs, Oid *argtypes,
				SPIPlanPtr *plan, Datum *values, const char *nulls, int result);
static void import_stats_from_file(char *filename, char *nspname, char *relname,
				char *attname);

/*
 * dbms_stats_import
 *   Import exported statistics from stdin or a file.
 *
 *   Order of arguments:
 *     1) schema name
 *     2) relation oid
 *     3) attribute name
 *     4) absolute path of source file, or 'stdin' (case insensitive)
 */
Datum
dbms_stats_import(PG_FUNCTION_ARGS)
{
	char		   *nspname;
	char		   *relname;
	char		   *attname;
	char		   *filename;	/* filename, or NULL for STDIN */
	int				ret;
	int				i;
	uint32			r_num;
	HeapTuple	   *r_tups;
	TupleDesc		r_tupdesc;
	SPIPlanPtr		r_upd_plan = NULL;
	SPIPlanPtr		r_ins_plan = NULL;
	SPIPlanPtr		c_sel_plan = NULL;
	SPIPlanPtr		c_del_plan = NULL;
	SPIPlanPtr		c_ins_plan = NULL;

	/* get validated arguments */
	get_args(fcinfo, &nspname, &relname, &attname, &filename);

	/* for debug use */
	elog(DEBUG3, "%s() f=%s n=%s r=%s a=%s", __FUNCTION__,
		 filename ? filename : "(null)",
		 nspname ? nspname : "(null)",
		 relname ? relname : "(null)",
		 attname ? attname : "(null)");

	/* connect to SPI */
	ret = SPI_connect();
	if (ret != SPI_OK_CONNECT)
		elog(ERROR, "pg_dbms_stats: SPI_connect => %d", ret);

	/* lock dummy statistics tables. */
	spi_exec_utility("LOCK dbms_stats.relation_stats_locked"
						" IN SHARE UPDATE EXCLUSIVE MODE");
	spi_exec_utility("LOCK dbms_stats.column_stats_locked"
						" IN SHARE UPDATE EXCLUSIVE MODE");

	/*
	 * Create a temp table to save the statistics to import.
	 * This table should fit with the content of export files.
	 */
	spi_exec_utility("CREATE TEMP TABLE dbms_stats_work_stats ("
					 "nspname          name   NOT NULL,"
					 "relname          name   NOT NULL,"
					 "relpages         int4   NOT NULL,"
					 "reltuples        float4 NOT NULL,"
					 "relallvisible    int4   NOT NULL,"
					 "curpages         int4   NOT NULL,"
					 "last_analyze     timestamp with time zone,"
					 "last_autoanalyze timestamp with time zone,"
					 "attname          name,"
					 "nspname_of_typename name,"
					 "typname name,"
					 "atttypmod int4,"
					 "stainherit       bool,"
					 "stanullfrac      float4,"
					 "stawidth         int4,"
					 "stadistinct      float4,"
					 "stakind1         int2,"
					 "stakind2         int2,"
					 "stakind3         int2,"
					 "stakind4         int2,"
					 "stakind5         int2,"
					 "staop1           oid,"
					 "staop2           oid,"
					 "staop3           oid,"
					 "staop4           oid,"
					 "staop5           oid,"
					 "stacoll1         oid,"
					 "stacoll2         oid,"
					 "stacoll3         oid,"
					 "stacoll4         oid,"
					 "stacoll5         oid,"
					 "stanumbers1      float4[],"
					 "stanumbers2      float4[],"
					 "stanumbers3      float4[],"
					 "stanumbers4      float4[],"
					 "stanumbers5      float4[],"
					 "stavalues1       dbms_stats.anyarray,"
					 "stavalues2       dbms_stats.anyarray,"
					 "stavalues3       dbms_stats.anyarray,"
					 "stavalues4       dbms_stats.anyarray"
					",stavalues5       dbms_stats.anyarray"
					 ")");

	/* load the statistics from export file to the temp table */
	import_stats_from_file(filename, nspname, relname, attname);

	/* Determine the Oid of local table from the tablename and schemaname. */
	ret = SPI_execute("SELECT DISTINCT w.nspname, w.relname, c.oid, "
							 "w.relpages, w.reltuples, "
							 "w.curpages, w.last_analyze, w.last_autoanalyze "
							 ",w.relallvisible "
						"FROM pg_catalog.pg_class c "
						"JOIN pg_catalog.pg_namespace n "
						  "ON (c.relnamespace = n.oid) "
					   "RIGHT JOIN dbms_stats_work_stats w "
						  "ON (w.relname = c.relname AND w.nspname = n.nspname) "
					   "ORDER BY 1, 2", false, 0);
	if (ret != SPI_OK_SELECT)
		elog(ERROR, "pg_dbms_stats: SPI_execute => %d", ret);

	/*
	 * If there is no record in the staging table after loading source and
	 * deleting unnecessary records, we treat it as an error.
	 */
	if (SPI_processed == 0)
		elog(ERROR, "no per-table statistic data to be imported");

	/* */
	r_num = SPI_processed;
	r_tups = SPI_tuptable->vals;
	r_tupdesc = SPI_tuptable->tupdesc;
	for (i = 0; i < r_num; i++)
	{
		bool	isnull;
		Datum	w_nspname;
		Datum	w_relname;
		Datum	w_relid;
		Datum	values[9];
		char	nulls[9] = {'t', 't', 't', 't', 't', 't', 't', 't', 't'};
		Oid		r_types[9] = {NAMEOID, NAMEOID, INT4OID, FLOAT4OID, INT4OID,
							  TIMESTAMPTZOID, TIMESTAMPTZOID, OIDOID, INT4OID};
		Oid		c_types[5] = {OIDOID, INT2OID, NAMEOID, NAMEOID,
							  NAMEOID};
		uint32		c_num;
		TupleDesc	c_tupdesc;
		HeapTuple  *c_tups;
		int			j;

		values[0] = w_nspname = SPI_getbinval(r_tups[i], r_tupdesc, 1, &isnull);
		values[1] = w_relname = SPI_getbinval(r_tups[i], r_tupdesc, 2, &isnull);
		values[7] = w_relid = SPI_getbinval(r_tups[i], r_tupdesc, 3, &isnull);
		if (isnull)
		{
			elog(WARNING, "relation \"%s.%s\" does not exist",
					DatumGetName(w_nspname)->data,
					DatumGetName(w_relname)->data);
			continue;
		}

		values[2] = SPI_getbinval(r_tups[i], r_tupdesc, 4, &isnull);
		values[3] = SPI_getbinval(r_tups[i], r_tupdesc, 5, &isnull);
		values[4] = SPI_getbinval(r_tups[i], r_tupdesc, 6, &isnull);
		values[5] = SPI_getbinval(r_tups[i], r_tupdesc, 7, &isnull);
		nulls[5] = isnull ? 'n' : 't';
		values[6] = SPI_getbinval(r_tups[i], r_tupdesc, 8, &isnull);
		nulls[6] = isnull ? 'n' : 't';
		values[8] = SPI_getbinval(r_tups[i], r_tupdesc, 9, &isnull);

		/*
		 * First we try UPDATE with the oid.  When no record matched, try
		 * INSERT.  We can't use DELETE-then-INSERT method because we have FK
		 * on relation_stats_locked so DELETE would delete child records in
		 * column_stats_locked undesirably.
		 */
		spi_exec_query("UPDATE dbms_stats.relation_stats_locked SET "
				"relname = quote_ident($1) || '.' || quote_ident($2), "
				"relpages = $3, reltuples = $4, relallvisible = $9, "
				"curpages = $5, last_analyze = $6, last_autoanalyze = $7 "
				"WHERE relid = $8",
				RELATION_PARAM_NUM, r_types, &r_upd_plan, values, nulls,
				SPI_OK_UPDATE);
		if (SPI_processed == 0)
		{
			spi_exec_query("INSERT INTO dbms_stats.relation_stats_locked "
					"(relname, relpages, reltuples, curpages, "
					"last_analyze, last_autoanalyze, relid, relallvisible"
					") VALUES (quote_ident($1) || '.' || quote_ident($2), "
					"$3, $4, $5, $6, $7, $8, $9)",
					RELATION_PARAM_NUM, r_types, &r_ins_plan, values, nulls,
					SPI_OK_INSERT);
			/*  If we failed to insert, we can't proceed. */
			if (SPI_processed != 1)
				elog(ERROR, "failed to insert import data");
		}

		elog(DEBUG2, "\"%s.%s\" relation statistic import",
			DatumGetName(w_nspname)->data, DatumGetName(w_relname)->data);

		/*
		 * Determine the attnum of the attribute with given name, and load
		 * statistics from temp table into dbms.column_stats_locked.
		 */
		spi_exec_query("SELECT w.stainherit, w.attname, a.attnum, "
							  "w.nspname_of_typename, tn.nspname, "
							  "w.typname, t.typname, w.atttypmod, a.atttypmod "
						 "FROM pg_catalog.pg_class c "
						 "JOIN pg_catalog.pg_namespace cn "
						   "ON (cn.oid = c.relnamespace) "
						 "JOIN pg_catalog.pg_attribute a "
						   "ON (a.attrelid = c.oid) "
						 "JOIN pg_catalog.pg_type t "
						   "ON (t.oid = a.atttypid) "
						 "JOIN pg_catalog.pg_namespace tn "
						   "ON (tn.oid = t.typnamespace) "
						"RIGHT JOIN dbms_stats_work_stats w "
						   "ON (w.nspname = cn.nspname AND w.relname = c.relname "
							   "AND (w.attname = a.attname OR w.attname = '')) "
						"WHERE w.nspname = $1 AND w.relname = $2 "
						  "AND a.attnum > 0"
						"ORDER BY 1, 3, 2",
				2, r_types, &c_sel_plan, values, NULL, SPI_OK_SELECT);

		/* This query ought to return at least one record. */
		if (SPI_processed == 0)
			elog(ERROR, "no per-column statistic data to be imported");

		values[0] = w_relid;
		values[2] = w_nspname;
		values[3] = w_relname;

		c_num = SPI_processed;
		c_tups = SPI_tuptable->vals;
		c_tupdesc = SPI_tuptable->tupdesc;
		for (j = 0; j < c_num; j++)
		{
			char   *w_typnamespace;
			char   *a_typnamespace;
			char   *w_typname;
			char   *a_typname;
			int		w_typmod;
			int		a_typmod;

			/*
			 * If we have only per-relation statistics in source, all of
			 * column_stats_effective for per-column statistics are NULL.
			 */
			(void) SPI_getbinval(c_tups[j], c_tupdesc, 1, &isnull);
			if (isnull)
				continue;

			/*
			 * If there is no column with given name, we skip the rest of
			 * import process.
			 */
			values[4] = SPI_getbinval(c_tups[j], c_tupdesc, 2, &isnull);
			values[1] = SPI_getbinval(c_tups[j], c_tupdesc, 3, &isnull);
			if (isnull)
			{
				elog(WARNING, "column \"%s\" of \"%s.%s\" does not exist",
					DatumGetName(values[4])->data,
						DatumGetName(w_nspname)->data,
						DatumGetName(w_relname)->data);
				continue;
			}

			/*
			 * If the destination column has different data type from source
			 * column, we stop importing to avoid corrupted statistics.
			 */
			w_typnamespace = DatumGetName(SPI_getbinval(c_tups[j], c_tupdesc, 4,
						&isnull))->data;
			a_typnamespace = DatumGetName(SPI_getbinval(c_tups[j], c_tupdesc, 5,
						&isnull))->data;
			w_typname = DatumGetName(SPI_getbinval(c_tups[j], c_tupdesc, 6,
						&isnull))->data;
			a_typname = DatumGetName(SPI_getbinval(c_tups[j], c_tupdesc, 7,
						&isnull))->data;
			if (strcmp(w_typnamespace, a_typnamespace) != 0 ||
				strcmp(w_typname, a_typname) != 0)
			{
				ereport(WARNING,
						(errcode(ERRCODE_DATATYPE_MISMATCH),
						 errmsg("column \"%s\" is of type \"%s.%s\""
								" but import data is of type \"%s.%s\"",
								DatumGetName(values[4])->data,
								a_typnamespace, a_typname,
								w_typnamespace, w_typname)));
				continue;
			}

			/*
			 * If the atttypmod of the destination column is different from the
			 * one of source, column, we stop importing to avoid corrupted
			 * statistics.
			 */
			w_typmod = DatumGetInt32(SPI_getbinval(c_tups[j], c_tupdesc, 8,
						&isnull));
			a_typmod = DatumGetInt32(SPI_getbinval(c_tups[j], c_tupdesc, 9,
						&isnull));
			if (w_typmod != a_typmod)
			{
				ereport(WARNING,
						(errcode(ERRCODE_DATATYPE_MISMATCH),
						 errmsg("column \"%s\" is of atttypmod %d"
								" but import data is of atttypmod %d",
								DatumGetName(values[4])->data,
								a_typmod, a_typmod)));
				continue;
			}

			/*
			 * First delete old dummy statistics, and import new one.  We use
			 * DELETE-then-INSERT method here to simplify codes.
			 */
			spi_exec_query("DELETE FROM dbms_stats.column_stats_locked "
					"WHERE starelid = $1 AND staattnum = $2", 2, c_types,
					&c_del_plan, values, NULL, SPI_OK_DELETE);

			spi_exec_query("INSERT INTO dbms_stats.column_stats_locked "
				"SELECT $1, $2, "
				"stainherit, stanullfrac, stawidth, stadistinct, "
				"stakind1, stakind2, stakind3, stakind4, stakind5, "
				"staop1, staop2, staop3, staop4, staop5, "
				"stacoll1, stacoll2, stacoll3, stacoll4, stacoll5, "
				"stanumbers1, stanumbers2, stanumbers3, stanumbers4, "
				"stanumbers5, "
				"stavalues1, stavalues2, stavalues3, stavalues4 , stavalues5 "
				"FROM dbms_stats_work_stats "
				"WHERE nspname = $3 AND relname = $4 "
				"AND attname = $5 "
				"ORDER BY 3",
				5, c_types, &c_ins_plan, values, NULL, SPI_OK_INSERT);

			elog(DEBUG2, "\"%s.%s.%s\" column statistic import",
				DatumGetName(w_nspname)->data,
				DatumGetName(w_relname)->data, DatumGetName(values[4])->data);
		}

		if (c_num == 0)
			elog(DEBUG2, "\"%s.%s\" column statistic no data",
				DatumGetName(w_nspname)->data, DatumGetName(w_relname)->data);
	}

	/* release the cached plan */
	SPI_freeplan(r_upd_plan);
	SPI_freeplan(r_ins_plan);
	SPI_freeplan(c_sel_plan);
	SPI_freeplan(c_del_plan);
	SPI_freeplan(c_ins_plan);

	/* delete the temp table */
	spi_exec_utility("DROP TABLE dbms_stats_work_stats");

	/* disconnect SPI */
	ret = SPI_finish();
	if (ret != SPI_OK_FINISH)
		elog(ERROR, "pg_dbms_stats: SPI_finish => %d", ret);

	/*
	 * Recover the protocol state because it has been invalidated by our
	 * COPY-from-stdin.
	 */
	if (filename == NULL)
		pq_puttextmessage('C', "dbms_stats_import");

	PG_RETURN_VOID();
}

/*
 * spi_exec_utility
 *   Execute given utility command via SPI.
 */
static void
spi_exec_utility(const char *query)
{
	int	ret;

	ret = SPI_exec(query, 0);
	if (ret != SPI_OK_UTILITY)
		elog(ERROR, "pg_dbms_stats: SPI_exec => %d", ret);
}

/*
 * spi_exec_query
 *   Execute given SQL command via SPI.
 *   The plan will be cached by SPI_prepare if it hasn't been.
 */
static void
spi_exec_query(const char *query, int nargs, Oid *argtypes, SPIPlanPtr *plan,
				Datum *values, const char *nulls, int result)
{
	int	ret;

	if (*plan == NULL)
		*plan = SPI_prepare(query, nargs, argtypes);

	ret = SPI_execute_plan(*plan, values, nulls, false, 0);
	if (ret != result)
		elog(ERROR, "pg_dbms_stats: SPI_execute_plan => %d", ret);
}

static char *
get_text_arg(FunctionCallInfo fcinfo, int n, bool is_name)
{
	text   *arg;
	char   *s;
	int		len;
	char   *result;

	arg = PG_GETARG_TEXT_PP(n);
	s = text_to_cstring(arg);
	PG_FREE_IF_COPY(arg, n);

	if (!is_name)
		return s;

	len = strlen(s);

	/* Truncate oversize input */
	if (len >= NAMEDATALEN)
		len = pg_mbcliplen(s, len, NAMEDATALEN - 1);

	/* We use palloc0 here to ensure result is zero-padded */
	result = (char *) palloc0(NAMEDATALEN);
	memcpy(result, s, len);
	pfree(s);

	return result;
}

/*
 * get_args
 *   Retrieve arguments from FunctionCallInfo and validate them.  We assume
 *   that order of arguments is:
 *     1) schema name
 *     2) relation oid
 *     3) attribute name
 *     4) absolute path of source file, or 'stdin' (case insensitive)
 */
static void
get_args(FunctionCallInfo fcinfo, char **nspname, char **relname,
		char **attname, char **filename)
{
	Oid				nspid;
	Oid				relid;
	AttrNumber		attnum;
	HeapTuple		tp;
	Form_pg_class	reltup;
	char			relkind;

	*nspname = *relname = *attname = *filename = NULL;

	/*
	 * First of all, check whether combination of arguments is consistent.
	 *
	 * 1) relid and attname can't be used with schemaname.
	 * 2) relid is required when attname is given.
	 */
	if (!PG_ARGISNULL(0) && (!PG_ARGISNULL(1) || !PG_ARGISNULL(2)))
		elog(ERROR, "relid and attnum can not be used with schemaname");
	else if (PG_ARGISNULL(1) && !PG_ARGISNULL(2))
		elog(ERROR, "relation is required");

	/* filepath validation */
	if (!PG_ARGISNULL(3))
	{
		*filename = get_text_arg(fcinfo, 3, false);

		/*
		 * If given filepath is "stdin", clear filename to tell caller to
		 * import from standard input.  Note that we accept only absolute path
		 * for security reason.
		 */
		if (pg_strcasecmp(*filename, "stdin") == 0)
			*filename = NULL;
		else if (!is_absolute_path(*filename))
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_NAME),
					 errmsg("relative path not allowed for dbms_stats_export"
							" to file")));
	}

	/* schemaname validation */
	if (!PG_ARGISNULL(0))
	{
		*nspname = get_text_arg(fcinfo, 0, true);

		/* check that a schema with given name exists */
		get_namespace_oid(*nspname, false);

		/* check that given schema is not one of system schemas */
		if (dbms_stats_is_system_schema_internal(*nspname))
			elog(ERROR, "\"%s\" is a system catalog", *nspname);
	}

	/* table oid validation */
	if (!PG_ARGISNULL(1))
	{
		relid = PG_GETARG_OID(1);
		tp = SearchSysCache1(RELOID, ObjectIdGetDatum(relid));
		if (!HeapTupleIsValid(tp))
			elog(ERROR, "relid %d does not exist", relid);

		/* check that the target is an ordinary table or an index */
		reltup = (Form_pg_class) GETSTRUCT(tp);
		*relname = pstrdup(reltup->relname.data);
		relkind = reltup->relkind;
		nspid = reltup->relnamespace;
		ReleaseSysCache(tp);

		if (relkind != RELKIND_RELATION && relkind != RELKIND_INDEX
			&& relkind != RELKIND_FOREIGN_TABLE
#if PG_VERSION_NUM >= 90300
			&& relkind != RELKIND_MATVIEW
#endif
		)
			elog(ERROR, "relkind of \"%s\" is \"%c\", can not import",
				get_rel_name(relid), relkind);

		/* check that the relation is not in one of system schemas */
		*nspname = get_namespace_name(nspid);
		if (dbms_stats_is_system_schema_internal(*nspname))
			elog(ERROR, "\"%s\" is a system catalog", *nspname);

		/* attribute name validation */
		if (!PG_ARGISNULL(2))
		{
			*attname = get_text_arg(fcinfo, 2, true);
			attnum = get_attnum(relid, *attname);
			if (!AttributeNumberIsValid(attnum))
				elog(ERROR, "column \"%s\" of \"%s.%s\" does not exist", *attname, *nspname, *relname);
		}
	}
}

/*
 * appendLiteral - Format a string as a SQL literal, append to buf
 *
 * This function was copied from simple_quote_literal() in
 * src/backend/utils/adt/ruleutils.c
 */
static void
appendLiteral(StringInfo buf, const char *val)
{
	const char *valptr;

	/*
	 * We form the string literal according to the prevailing setting of
	 * standard_conforming_strings; we never use E''. User is responsible for
	 * making sure result is used correctly.
	 */
	appendStringInfoChar(buf, '\'');
	for (valptr = val; *valptr; valptr++)
	{
		char		ch = *valptr;

		if (SQL_STR_DOUBLE(ch, !standard_conforming_strings))
			appendStringInfoChar(buf, ch);
		appendStringInfoChar(buf, ch);
	}
	appendStringInfoChar(buf, '\'');
}

/*
 * import_stats_from_file
 *	 load data from file or stdin into work table, and delete unnecessary
 *	 records.
 */
static void
import_stats_from_file(char *filename, char *nspname, char *relname,
	char *attname)
{
	StringInfoData	buf;
	List		   *parsetree_list;
	uint64			processed;
	Datum			values[3];
	Oid				argtypes[3] = { CSTRINGOID, CSTRINGOID, CSTRINGOID };
	char			nulls[3] = { 'n', 'n', 'n' };
	int				nargs;
	int				ret;

	/* for debug use */
	elog(DEBUG3, "%s() f=%s n=%s r=%s a=%s", __FUNCTION__,
		 filename ? filename : "(null)",
		 nspname ? nspname : "(null)",
		 relname ? relname : "(null)",
		 attname ? attname : "(null)");

	/*
	 * Construct COPY statement.  NULL for filename indicates that source is
	 * stdin.
	 */
	initStringInfo(&buf);
	appendStringInfoString(&buf, "COPY dbms_stats_work_stats FROM ");
	if (filename == NULL)
		appendStringInfoString(&buf, "stdin");
	else
		appendLiteral(&buf, filename);

	appendStringInfoString(&buf, " (FORMAT 'binary')");

	/* Execute COPY FROM command. */
	parsetree_list = pg_parse_query(buf.data);

#if PG_VERSION_NUM >= 100000
	{
		/* 
		 * parsetree_list is a list with one RawStmt since Pg10. Extract
		 * CopyStmt to feed to DoCopy.
		 */
		ParseState	*pstate = make_parsestate(NULL);
		RawStmt *rstmt = (RawStmt *)linitial (parsetree_list);
		CopyStmt *stmt = (CopyStmt *)rstmt->stmt;

		Assert(IsA(stmt, CopyStmt));

		pstate->p_sourcetext = pstrdup(buf.data);
		DoCopy(pstate, stmt, rstmt->stmt_location, rstmt->stmt_len, &processed);
		free_parsestate(pstate);
	}
#elif PG_VERSION_NUM >= 90300
	DoCopy((CopyStmt *)linitial(parsetree_list), buf.data, &processed);
#else
	processed = DoCopy((CopyStmt *)linitial(parsetree_list), buf.data);
#endif

	if (processed == 0)
		elog(ERROR, "no data to be imported");

	/*
	 * Delete the statistics other than the specified object's statistic from
	 * the temp table.  We can skip DELETEing staging data when schemaname is
	 * NULL, because it means database-wise import.
	 */
	if (nspname == NULL)
		return;

	resetStringInfo(&buf);
	appendStringInfoString(&buf,
						   "DELETE FROM dbms_stats_work_stats "
						   " WHERE nspname <> $1::text ");
	values[0] = CStringGetDatum(nspname);
	nulls[0] = 't';
	nargs = 1;

	if (relname != NULL)
	{
		values[1] = CStringGetDatum(relname);
		nulls[1] = 't';
		nargs++;
		appendStringInfoString(&buf, " OR (relname <> $2::text) ");

		if (attname != NULL)
		{
			values[2] = CStringGetDatum(attname);
			nulls[2] = 't';
			nargs++;
			appendStringInfoString(&buf, " OR (attname <> $3::text) ");
		}
	}

	ret = SPI_execute_with_args(buf.data, nargs, argtypes, values, nulls,
								 false, 0);
	if (ret != SPI_OK_DELETE)
		elog(ERROR, "pg_dbms_stats: SPI_execute_with_args => %d", ret);
}

#ifdef UNIT_TEST
void test_import(int *passed, int *total);
static void test_spi_exec_query(int *passed, int *total);
static void test_spi_exec_utility(int *passed, int *total);
static void test_appendLiteral(int *passed, int *total);

#define StringEq(actual, expected)	\
		(strcmp((actual), (expected)) == 0 ? 1 : 0)

/*
 * Test appendLiteral function
 */
static void
test_appendLiteral(int *passed, int *total)
{
	bool			org_standard_conforming_strings;
	int				caseno = 0;
	StringInfoData	buf;

	/* Backup current GUC parameters */
	NewGUCNestLevel();
	org_standard_conforming_strings = standard_conforming_strings;

	/* Initialize resources for tests */
	initStringInfo(&buf);

	/*
	 * *-*-1:
	 *   - no special char
	 */
	caseno++;
	resetStringInfo(&buf);
	appendStringInfoString(&buf, "BEFORE");
	appendLiteral(&buf, "\"abc 123\tあいう\n\"");
	if (StringEq(buf.data, "BEFORE'\"abc 123\tあいう\n\"'"))
	{
		elog(WARNING, "%s-%d ok", __FUNCTION__, caseno);
		(*passed)++;
	}
	else
	{
		elog(WARNING, "%s-%d failed: [%s]", __FUNCTION__, caseno, buf.data);
	}

	/*
	 * *-*-2:
	 *   - contains special chars (single quote, back slash),
	 *   - standard_conforming_strings is true
	 */
	caseno++;
	resetStringInfo(&buf);
	appendStringInfoString(&buf, "BEFORE");
	standard_conforming_strings = true;
	appendLiteral(&buf, "'abc 123\tあいう\n\\");
	if (StringEq(buf.data, "BEFORE'''abc 123\tあいう\n\\'"))
	{
		elog(WARNING, "%s-%d ok", __FUNCTION__, caseno);
		(*passed)++;
	}
	else
	{
		elog(WARNING, "%s-%d failed: [%s]", __FUNCTION__, caseno, buf.data);
	}

	/*
	 * *-*-3:
	 *   - contains special chars (single quote, back slash),
	 *   - standard_conforming_strings is false
	 */
	caseno++;
	resetStringInfo(&buf);
	appendStringInfoString(&buf, "BEFORE");
	standard_conforming_strings = false;
	appendLiteral(&buf, "'abc 123\tあいう\n\\");
	if (StringEq(buf.data, "BEFORE'''abc 123\tあいう\n\\\\'"))
	{
		elog(WARNING, "%s-%d ok", __FUNCTION__, caseno);
		(*passed)++;
	}
	else
	{
		elog(WARNING, "%s-%d failed: [%s]", __FUNCTION__, caseno, buf.data);
	}

	/*
	 * *-*-4:
	 *   - empty string
	 */
	caseno++;
	resetStringInfo(&buf);
	appendStringInfoString(&buf, "BEFORE");
	appendLiteral(&buf, "");
	if (StringEq(buf.data, "BEFORE''"))
	{
		elog(WARNING, "%s-%d ok", __FUNCTION__, caseno);
		(*passed)++;
	}
	else
	{
		elog(WARNING, "%s-%d failed: [%s]", __FUNCTION__, caseno, buf.data);
	}

	/* report # of tests */
	*total += caseno;

	/* Restore GUC parameters */
	standard_conforming_strings = org_standard_conforming_strings;
}

static void
test_spi_exec_query(int *passed, int *total)
{
	int				rc;
	volatile int	caseno = 0;
	SPIPlanPtr		ptr = NULL;
	SPIPlanPtr		org_ptr;

	/* Initialize */
	rc = SPI_connect();
	if (rc != SPI_OK_CONNECT)
		elog(ERROR, "could not connect SPI: %s", SPI_result_code_string(rc));

	/*
	 * *-*-1
	 *   - plan is not cached
	 */
	caseno++;
	BeginInternalSubTransaction("test");
	PG_TRY();
	{
		spi_exec_query("SELECT 1", 0, NULL, &ptr, NULL, NULL, SPI_OK_SELECT);
		if (ptr != NULL && SPI_processed == 1)
		{
			elog(WARNING, "%s-%d ok", __FUNCTION__, caseno);
			(*passed)++;
		}
		ReleaseCurrentSubTransaction();
	}
	PG_CATCH();
	{
		elog(WARNING, "*-*-%d failed", caseno);
		RollbackAndReleaseCurrentSubTransaction();
		SPI_restore_connection();
	}
	PG_END_TRY();

	/*
	 * *-*-2
	 *   - plan is cached
	 */
	caseno++;
	BeginInternalSubTransaction("test");
	PG_TRY();
	{
		org_ptr = ptr;
		spi_exec_query(NULL, 0, NULL, &ptr, NULL, NULL, SPI_OK_SELECT);
		if (ptr == org_ptr && SPI_processed == 1)
		{
			elog(WARNING, "%s-%d ok", __FUNCTION__, caseno);
			(*passed)++;
		}
		ReleaseCurrentSubTransaction();
	}
	PG_CATCH();
	{
		elog(WARNING, "*-*-%d failed", caseno);
		RollbackAndReleaseCurrentSubTransaction();
		FlushErrorState();
		SPI_restore_connection();
	}
	PG_END_TRY();
	SPI_freeplan(ptr);
	ptr = NULL;

	/*
	 * *-*-3
	 *   - query error
	 */
	caseno++;
	BeginInternalSubTransaction("test");
	PG_TRY();
	{
		spi_exec_query("SELECT 1 / 0",
					   0, NULL, &ptr, NULL, NULL, SPI_OK_SELECT);
		elog(WARNING, "*-*-%d failed", caseno);
		ReleaseCurrentSubTransaction();
	}
	PG_CATCH();
	{
		elog(WARNING, "%s-%d ok", __FUNCTION__, caseno);
		(*passed)++;
		RollbackAndReleaseCurrentSubTransaction();
		FlushErrorState();
		SPI_restore_connection();
	}
	PG_END_TRY();
	SPI_freeplan(ptr);
	ptr = NULL;

	/*
	 * *-*-4
	 *   - query success
	 */
	caseno++;
	BeginInternalSubTransaction("test");
	PG_TRY();
	{
		spi_exec_query("SELECT 1", 0, NULL, &ptr, NULL, NULL, SPI_OK_SELECT);
		if (ptr != NULL && SPI_processed == 1)
		{
			elog(WARNING, "%s-%d ok", __FUNCTION__, caseno);
			(*passed)++;
		}
		ReleaseCurrentSubTransaction();
	}
	PG_CATCH();
	{
		elog(WARNING, "*-*-%d failed", caseno);
		PG_RE_THROW();
		RollbackAndReleaseCurrentSubTransaction();
		SPI_restore_connection();
	}
	PG_END_TRY();
	SPI_freeplan(ptr);
	ptr = NULL;

	/* report # of tests */
	(*total) += caseno;

	/* Cleanup */
	rc = SPI_finish();
	if (rc != SPI_OK_FINISH && rc != SPI_ERROR_UNCONNECTED)
		elog(ERROR, "could not finish SPI: %s", SPI_result_code_string(rc));
}

static void
test_spi_exec_utility(int *passed, int *total)
{
	int				rc;
	volatile int	caseno = 0;

	/* Initialize */
	rc = SPI_connect();
	if (rc != SPI_OK_CONNECT)
		elog(ERROR, "could not connect SPI: %s", SPI_result_code_string(rc));

	/*
	 * *-*-1
	 *   - query error
	 */
	caseno++;
	BeginInternalSubTransaction("test");
	PG_TRY();
	{
		spi_exec_utility("RESET dummy_parameter");
		elog(WARNING, "*-*-%d failed", caseno);
		ReleaseCurrentSubTransaction();
	}
	PG_CATCH();
	{
		elog(WARNING, "%s-%d ok", __FUNCTION__, caseno);
		(*passed)++;
		RollbackAndReleaseCurrentSubTransaction();
		FlushErrorState();
		SPI_restore_connection();
	}
	PG_END_TRY();

	/*
	 * *-*-2
	 *   - query success
	 */
	caseno++;
	BeginInternalSubTransaction("test");
	PG_TRY();
	{
		spi_exec_utility("RESET client_min_messages");
		elog(WARNING, "%s-%d ok", __FUNCTION__, caseno);
		(*passed)++;
		ReleaseCurrentSubTransaction();
	}
	PG_CATCH();
	{
		elog(WARNING, "*-*-%d failed", caseno);
		RollbackAndReleaseCurrentSubTransaction();
		SPI_restore_connection();
	}
	PG_END_TRY();

	/* report # of tests */
	(*total) += caseno;

	/* Cleanup */
	rc = SPI_finish();
	if (rc != SPI_OK_FINISH && rc != SPI_ERROR_UNCONNECTED)
		elog(ERROR, "could not finish SPI: %s", SPI_result_code_string(rc));
}

/*
 * Unit test entry point for import.c.  This will be called by PG_init()
 * function, after initialization for this extension is completed .
 * This funciton should add the numbers of tests passed and the total number of
 * tests to parameter passed and total respectively.
 */
void
test_import(int *passed, int *total)
{
	int local_passed = 0;
	int local_total = 0;

	elog(WARNING, "==========");

	/* Do tests here */
	test_appendLiteral(&local_passed, &local_total);
	test_spi_exec_query(&local_passed, &local_total);
	test_spi_exec_utility(&local_passed, &local_total);

	elog(WARNING, "%s %d/%d passed", __FUNCTION__, local_passed, local_total);
	*passed += local_passed;
	*total += local_total;
}

#endif
