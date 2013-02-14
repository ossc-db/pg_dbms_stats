/*
 * pg_dbms_stats.c
 *
 * Copyright (c) 2009-2012, NIPPON TELEGRAPH AND TELEPHONE CORPORATION
 * Portions Copyright (c) 1996-2011, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 */
#include "postgres.h"

#include "access/transam.h"
#include "catalog/pg_statistic.h"
#include "catalog/pg_type.h"
#include "commands/trigger.h"
#include "executor/spi.h"
#include "funcapi.h"
#include "optimizer/plancat.h"
#include "storage/bufmgr.h"
#include "utils/builtins.h"
#include "utils/guc.h"
#include "utils/inval.h"
#include "utils/lsyscache.h"
#include "utils/selfuncs.h"
#include "utils/syscache.h"
#if PG_VERSION_NUM >= 90200
#include "utils/rel.h"
#endif

#include "pg_dbms_stats.h"

PG_MODULE_MAGIC;

/* Error levels used by pg_dbms_stats */
#define ELEVEL_DEBUG		DEBUG3	/* log level for debug information */
#define ELEVEL_BADSTATS		LOG		/* log level for invalid statistics */

#define MAX_REL_CACHE		50		/* expected max # of rel stats entries */

/* represents an element of relation statistics which is cached in hash table */
typedef struct StatsRelationEntry
{
	Oid					relid;		/* hash key must be at the head */

	bool				valid;		/* T if the entry has valid stats */

	BlockNumber			relpages;	/* # of pages as of last ANALYZE */
	double				reltuples;	/* # of tuples as of last ANALYZE */
	BlockNumber			relallvisible;	/* # of all-visible pages as of last
										 * ANALYZE */
	BlockNumber			curpages;	/* # of pages as of lock/restore */

	List			   *col_stats;	/* list of HeapTuple, each element is
									   pg_statistic record of this relation. */
} StatsRelationEntry;

/* Saved hook functions */
get_relation_info_hook_type		prev_get_relation_info = NULL;
get_attavgwidth_hook_type		prev_get_attavgwidth = NULL;
get_relation_stats_hook_type	prev_get_relation_stats = NULL;
get_index_stats_hook_type		prev_get_index_stats = NULL;

/* rows_query(oid) RETURNS int4, float4, int4 */
static const char  *rows_query =
	"SELECT relpages, reltuples, curpages"
#if PG_VERSION_NUM >= 90200
	", relallvisible"
#endif
	"  FROM dbms_stats.relation_stats_locked"
	" WHERE relid = $1";
static SPIPlanPtr	rows_plan = NULL;

/* tuple_query(oid, int2, bool) RETURNS pg_statistic */
static const char  *tuple_query =
	"SELECT * "
	"  FROM dbms_stats.column_stats_locked "
	" WHERE starelid = $1 "
	"   AND staattnum = $2 "
	"   AND stainherit = $3";
static SPIPlanPtr	tuple_plan = NULL;

/* GUC variables */
static bool			pg_dbms_stats_use_locked_stats = true;

/* Current nesting depth of SPI calls, used to prevent recursive calls */
static int			nested_level = 0;

/*
 * The relation_stats_effective statistic cache is stored in hash table.
 */
static HTAB	   *rel_stats;

#define get_pg_statistic(tuple)	((Form_pg_statistic) GETSTRUCT(tuple))

PG_FUNCTION_INFO_V1(dbms_stats_merge);
PG_FUNCTION_INFO_V1(dbms_stats_invalidate_relation_cache);
PG_FUNCTION_INFO_V1(dbms_stats_invalidate_column_cache);
PG_FUNCTION_INFO_V1(dbms_stats_is_system_schema);
PG_FUNCTION_INFO_V1(dbms_stats_is_system_catalog);

extern Datum dbms_stats_merge(PG_FUNCTION_ARGS);
extern Datum dbms_stats_invalidate_relation_cache(PG_FUNCTION_ARGS);
extern Datum dbms_stats_invalidate_column_cache(PG_FUNCTION_ARGS);
extern Datum dbms_stats_is_system_schema(PG_FUNCTION_ARGS);
extern Datum dbms_stats_is_system_catalog(PG_FUNCTION_ARGS);

static HeapTuple dbms_stats_merge_internal(HeapTuple lhs, HeapTuple rhs,
	TupleDesc tupledesc);
static void dbms_stats_check_tg_event(FunctionCallInfo fcinfo,
	TriggerData *trigdata, HeapTuple *invtup, HeapTuple *rettup);
static void dbms_stats_invalidate_cache_internal(Oid relid, bool sta_col);

/* Module callbacks */
void	_PG_init(void);
void	_PG_fini(void);

static void dbms_stats_get_relation_info(PlannerInfo *root, Oid relid,
	bool inhparent, RelOptInfo *rel);
static int32 dbms_stats_get_attavgwidth(Oid relid, AttrNumber attnum);
static bool dbms_stats_get_relation_stats(PlannerInfo *root, RangeTblEntry *rte,
	AttrNumber attnum, VariableStatData *vardata);
static bool dbms_stats_get_index_stats(PlannerInfo *root, Oid indexOid,
	AttrNumber indexattnum, VariableStatData *vardata);

static void get_merged_relation_stats(Oid relid, BlockNumber *pages,
	double *tuples, double *allvisfrac, bool estimate);
static int32 get_merged_avgwidth(Oid relid, AttrNumber attnum);
static HeapTuple get_merged_column_stats(Oid relid, AttrNumber attnum,
	bool inh);
static HeapTuple column_cache_search(Oid relid, AttrNumber attnum, bool inh);
static HeapTuple column_cache_enter(HeapTuple tuple);
static bool execute_plan(SPIPlanPtr *plan, const char *query, Oid relid,
	const AttrNumber *attnum, bool inh);
static void StatsCacheRelCallback(Datum arg, Oid relid);
static void init_rel_stats(void);
static void init_rel_stats_entry(StatsRelationEntry *entry, Oid relid);
/* copied from PG core source tree */
static void dbms_stats_estimate_rel_size(Relation rel, int32 *attr_widths,
				  BlockNumber *pages, double *tuples, double *allvisfrac,
				  BlockNumber curpages);
static int32 dbms_stats_get_rel_data_width(Relation rel, int32 *attr_widths);

/* Unit test suit functions */
#ifdef UNIT_TEST
extern void test_import(int *passed, int *total);
extern void test_dump(int *passed, int *total);
extern void test_pg_dbms_stats(int *passed, int *total);
#endif

/*
 * Module load callback
 */
void
_PG_init(void)
{
	/* Execute unit test cases */
#ifdef UNIT_TEST
	{
		int passed = 0;
		int total = 0;

		test_import(&passed, &total);
		test_dump(&passed, &total);
		test_pg_dbms_stats(&passed, &total);

		elog(WARNING, "TOTAL %d/%d passed", passed, total);
	}
#endif

	/* Define custom GUC variables. */
	DefineCustomBoolVariable("pg_dbms_stats.use_locked_stats",
							 "Enable user defined statistics.",
							 NULL,
							 &pg_dbms_stats_use_locked_stats,
							 true,
							 PGC_USERSET,
							 0,
							 NULL,
							 NULL,
							 NULL);

	EmitWarningsOnPlaceholders("pg_dbms_stats");

	/* Back up old hooks, and install ours. */
	prev_get_relation_info = get_relation_info_hook;
	get_relation_info_hook = dbms_stats_get_relation_info;
	prev_get_attavgwidth = get_attavgwidth_hook;
	get_attavgwidth_hook = dbms_stats_get_attavgwidth;
	prev_get_relation_stats = get_relation_stats_hook;
	get_relation_stats_hook = dbms_stats_get_relation_stats;
	prev_get_index_stats = get_index_stats_hook;
	get_index_stats_hook = dbms_stats_get_index_stats;

	/* Initialize hash table for statistics caching. */
	init_rel_stats();

	/* Also set up a callback for relcache SI invalidations */
	CacheRegisterRelcacheCallback(StatsCacheRelCallback, (Datum) 0);
}

/*
 * Module unload callback
 */
void
_PG_fini(void)
{
	/* Restore old hooks. */
	get_relation_info_hook = prev_get_relation_info;
	get_attavgwidth_hook = prev_get_attavgwidth;
	get_relation_stats_hook = prev_get_relation_stats;
	get_index_stats_hook = prev_get_index_stats;

	/* A function to unregister callback for relcache is NOT provided. */
}

/*
 * Store heap tuple header into given heap tuple.
 */
static void
AssignHeapTuple(HeapTuple htup, HeapTupleHeader header)
{
	htup->t_len = HeapTupleHeaderGetDatumLength(header);
	ItemPointerSetInvalid(&htup->t_self);
	htup->t_tableOid = InvalidOid;
	htup->t_data = header;
}

/*
 * dbms_stats_merge
 *   called by sql function 'dbms_stats.merge', and return the execution result
 *   of the function 'dbms_stats_merge_internal'.
 */
Datum
dbms_stats_merge(PG_FUNCTION_ARGS)
{
	HeapTupleData	lhs;
	HeapTupleData	rhs;
	TupleDesc		tupdesc;
	HeapTuple		ret = NULL;

	/* assign HeapTuple of the left statistics data unless null. */
	if (PG_ARGISNULL(0))
		lhs.t_data = NULL;
	else
		AssignHeapTuple(&lhs, PG_GETARG_HEAPTUPLEHEADER(0));

	/* assign HeapTuple of the right statistics data unless null. */
	if (PG_ARGISNULL(1))
		rhs.t_data = NULL;
	else
		AssignHeapTuple(&rhs, PG_GETARG_HEAPTUPLEHEADER(1));

	/* fast path for one-side is null */
	if (lhs.t_data == NULL && rhs.t_data == NULL)
		PG_RETURN_NULL();

	/* build a tuple descriptor for our result type */
	if (get_call_result_type(fcinfo, NULL, &tupdesc) != TYPEFUNC_COMPOSITE)
		elog(ERROR, "return type must be a row type");

	/* merge two statistics tuples into one, and return it */
	ret = dbms_stats_merge_internal(&lhs, &rhs, tupdesc);

	if (ret)
		PG_RETURN_DATUM(HeapTupleGetDatum(ret));
	else
		PG_RETURN_NULL();
}

/*
 * dbms_stats_merge_internal
 *   merge the dummy statistic (lhs) and the true statistic (rhs), on the basis
 *   of given TupleDesc.
 */
static HeapTuple
dbms_stats_merge_internal(HeapTuple lhs, HeapTuple rhs, TupleDesc tupdesc)
{
	Datum			values[Natts_pg_statistic];
	bool			nulls[Natts_pg_statistic];
	int				i;
	Oid				atttype = InvalidOid;

	/* fast path for both-sides are null */
	if ((lhs == NULL || lhs->t_data == NULL) &&
		(rhs == NULL || rhs->t_data == NULL))
		return NULL;

	/* fast path for one-side is null */
	if (lhs == NULL || lhs->t_data == NULL)
	{
		/* use right tuple */
		heap_deform_tuple(rhs, tupdesc, values, nulls);
		for (i = 0; i < Anum_pg_statistic_staop1 + STATISTIC_NUM_SLOTS - 1; i++)
			if (nulls[i])
				return NULL;	/* check null constraints */
	}
	else if (rhs == NULL || rhs->t_data == NULL)
	{
		/* use left tuple */
		heap_deform_tuple(lhs, tupdesc, values, nulls);
		for (i = 0; i < Anum_pg_statistic_staop1 + STATISTIC_NUM_SLOTS - 1; i++)
			if (nulls[i])
				return NULL;	/* check null constraints */
	}
	else
	{
		/*
		 * If the column value of the dummy statistic is not NULL, in the
		 * statistics except the slot, use it.  Otherwise we use the column
		 * value of the true statistic.
		 */
		heap_deform_tuple(lhs, tupdesc, values, nulls);
		for (i = 0; i < Anum_pg_statistic_stakind1 - 1; i++)
		{
			if (nulls[i])
			{
				values[i] = fastgetattr(rhs, i + 1, tupdesc, &nulls[i]);
				if (nulls[i])
				{
					ereport(ELEVEL_BADSTATS,
						(errmsg("pg_dbms_stats: bad statistics"),
						 errdetail("column \"%s\" should not be null",
							get_attname(StatisticRelationId,
										tupdesc->attrs[i]->attnum))));
					return NULL;	/* should not be null */
				}
			}
		}

		/*
		 * If the column value of the dummy statistic is not all NULL, in the
		 * statistics the slot, use it.  Otherwise we use the column
		 * value of the true statistic.
		 */
		for (; i < Anum_pg_statistic_staop1 + STATISTIC_NUM_SLOTS - 1; i++)
		{
			if (nulls[i])
			{
				for (i = Anum_pg_statistic_stakind1 - 1;
					 i < Anum_pg_statistic_stavalues1 + STATISTIC_NUM_SLOTS - 1;
					 i++)
				{
					values[i] = fastgetattr(rhs, i + 1, tupdesc, &nulls[i]);
					if (i < Anum_pg_statistic_staop1 + STATISTIC_NUM_SLOTS - 1 &&
						nulls[i])
					{
						ereport(ELEVEL_BADSTATS,
							(errmsg("pg_dbms_stats: bad statistics"),
							 errdetail("column \"%s\" should not be null",
								get_attname(StatisticRelationId,
											tupdesc->attrs[i]->attnum))));
						return NULL;	/* should not be null */
					}
				}

				break;
			}
		}
	}

	/* verify types to work around for ALTER COLUMN TYPE */
	for (i = 0; i < STATISTIC_NUM_SLOTS; i++)
	{
		if ((i + 1 == STATISTIC_KIND_MCV ||
			 i + 1 == STATISTIC_KIND_HISTOGRAM) &&
			!nulls[Anum_pg_statistic_stavalues1 + i - 1])
		{
			Oid			relid = DatumGetObjectId(values[0]);
			AttrNumber	attnum = DatumGetInt16(values[1]);
			ArrayType  *arr;

			if (atttype == InvalidOid)
				atttype = get_atttype(relid, attnum);

			arr = DatumGetArrayTypeP(
					values[Anum_pg_statistic_stavalues1 + i - 1]);
			if (arr == NULL || arr->elemtype != atttype)
			{
				char *attname = get_attname(relid,
									tupdesc->attrs[attnum - 1]->attnum);

				ereport(ELEVEL_BADSTATS,
					(errmsg("pg_dbms_stats: bad column type"),
					 errdetail("type of column \"%s\" has been changed",
						attname),
					 errhint("need to execute dbms_stats.unlock('%s', '%s')",
						get_rel_name(relid), attname)));
				return NULL;
			}
		}
	}

	return heap_form_tuple(tupdesc, values, nulls);
}

/*
 * dbms_stats_invalidate_relation_cache
 *   Register invalidation of the specified relation's relcache.
 *
 * CREATE TRIGGER dbms_stats.relation_stats_locked FOR INSERT, UPDATE, DELETE FOR EACH
 * ROWS EXECUTE ...
 */
Datum
dbms_stats_invalidate_relation_cache(PG_FUNCTION_ARGS)
{
	TriggerData		   *trigdata = (TriggerData *) fcinfo->context;
	HeapTuple			invtup;	/* tuple to be invalidated */
	HeapTuple			rettup;	/* tuple to be returned */
	Datum				value;
	bool				isnull;

	/* make sure it's called as a before/after trigger */
	dbms_stats_check_tg_event(fcinfo, trigdata, &invtup, &rettup);

	/*
	 * assume that position of dbms_stats.relation_stats_locked.relid is head value of
	 * tuple.
	 */
	value = fastgetattr(invtup, 1, trigdata->tg_relation->rd_att, &isnull);

	/*
	 * invalidate prepared statements and force re-planning with pg_dbms_stats.
	 */
	dbms_stats_invalidate_cache_internal((Oid)value, false);

	PG_RETURN_POINTER(rettup);
}

/*
 * dbms_stats_invalidate_column_cache
 *   Register invalidation of the specified relation's relcache.
 *
 * CREATE TRIGGER dbms_stats.column_stats_locked FOR INSERT, UPDATE, DELETE FOR EACH
 * ROWS EXECUTE ...
 */
Datum
dbms_stats_invalidate_column_cache(PG_FUNCTION_ARGS)
{
	TriggerData		   *trigdata = (TriggerData *) fcinfo->context;
	Form_pg_statistic	form;
	HeapTuple			invtup;	/* tuple to be invalidated */
	HeapTuple			rettup;	/* tuple to be returned */

	/* make sure it's called as a before/after trigger */
	dbms_stats_check_tg_event(fcinfo, trigdata, &invtup, &rettup);

	/*
	 * assume that both pg_statistic and dbms_stats.column_stats_locked have the same
	 * definition.
	 */
	form = get_pg_statistic(invtup);

	/*
	 * invalidate prepared statements and force re-planning with pg_dbms_stats.
	 */
	dbms_stats_invalidate_cache_internal(form->starelid, true);

	PG_RETURN_POINTER(rettup);
}

static void
dbms_stats_check_tg_event(FunctionCallInfo fcinfo,
						  TriggerData *trigdata,
						  HeapTuple *invtup,
						  HeapTuple *rettup)
{
	/* make sure it's called as a before/after trigger */
	if (!CALLED_AS_TRIGGER(fcinfo) ||
		!TRIGGER_FIRED_BEFORE(trigdata->tg_event) ||
		!TRIGGER_FIRED_FOR_ROW(trigdata->tg_event))
		elog(ERROR, "pg_dbms_stats: invalid trigger call");

	if (TRIGGER_FIRED_BY_INSERT(trigdata->tg_event))
	{
		/* INSERT */
		*rettup = *invtup = trigdata->tg_trigtuple;
	}
	else if (TRIGGER_FIRED_BY_DELETE(trigdata->tg_event))
	{
		/* DELETE */
		*rettup = *invtup = trigdata->tg_trigtuple;
	}
	else
	{
		/* UPDATE */
		*invtup = trigdata->tg_trigtuple;
		*rettup = trigdata->tg_newtuple;
	}
}

static void
dbms_stats_invalidate_cache_internal(Oid relid, bool sta_col)
{
	Relation	rel;

	/*
	 * invalidate prepared statements and force re-planning with pg_dbms_stats.
	 */
	rel = try_relation_open(relid, NoLock);
	if (rel != NULL)
	{
		if (sta_col &&
			rel->rd_rel->relkind == RELKIND_INDEX &&
			(rel->rd_indextuple == NULL ||
			 heap_attisnull(rel->rd_indextuple, Anum_pg_index_indexprs)))
			ereport(ERROR,
					(errcode(ERRCODE_WRONG_OBJECT_TYPE),
					 errmsg("\"%s\" is an index except an index expression",
							RelationGetRelationName(rel))));
		if (rel->rd_rel->relkind == RELKIND_COMPOSITE_TYPE)
			ereport(ERROR,
					(errcode(ERRCODE_WRONG_OBJECT_TYPE),
					 errmsg("\"%s\" is a composite type",
							RelationGetRelationName(rel))));

		/*
		 * We need to invalidate relcache of underlying table too, because
		 * CachedPlan mechanism decides to do re-planning when any relcache of
		 * used tables was invalid at EXECUTE.
		 */
		if (rel->rd_rel->relkind == RELKIND_INDEX &&
			rel->rd_index && OidIsValid(rel->rd_index->indrelid))
			CacheInvalidateRelcacheByRelid(rel->rd_index->indrelid);

		CacheInvalidateRelcache(rel);
		relation_close(rel, NoLock);
	}
}

/*
 * dbms_stats_is_system_schema
 *   called by sql function 'dbms_stats.is_system_schema', and return the
 *   result of the function 'dbms_stats_is_system_internal'.
 */
Datum
dbms_stats_is_system_schema(PG_FUNCTION_ARGS)
{
	text   *arg0;
	char   *schema_name;
	bool	result;

	arg0 = PG_GETARG_TEXT_PP(0);
	schema_name = text_to_cstring(arg0);
	result = dbms_stats_is_system_schema_internal(schema_name);

	PG_FREE_IF_COPY(arg0, 0);

	PG_RETURN_BOOL(result);
}

/*
 * dbms_stats_is_system_schema_internal
 *   return whether the given schema contains any system catalog.  Here we
 *   treat dbms_stats objects as system catalogs to avoid infinite loop.
 */
bool
dbms_stats_is_system_schema_internal(char *schema_name)
{
	Assert(schema_name != NULL);

	/* if the schema is system_schema, return true */
	if (strcmp(schema_name, "pg_catalog") == 0 ||
		strcmp(schema_name, "pg_toast") == 0 ||
		strcmp(schema_name, "information_schema") == 0 ||
		strcmp(schema_name, "dbms_stats") == 0)
		return true;

	return false;
}

/*
 * dbms_stats_is_system_catalog
 *   called by sql function 'dbms_stats.is_system_catalog', and return the
 *   result of the function 'dbms_stats_is_system_catalog_internal'.
 */
Datum
dbms_stats_is_system_catalog(PG_FUNCTION_ARGS)
{
	Oid		relid;
	bool	result;

	if (PG_ARGISNULL(0))
		PG_RETURN_BOOL(true);

	relid = PG_GETARG_OID(0);
	result = dbms_stats_is_system_catalog_internal(relid);

	PG_RETURN_BOOL(result);
}

/*
 * dbms_stats_is_system_catalog_internal
 *   Check whether the given relation is one of system catalogs.
 */
bool
dbms_stats_is_system_catalog_internal(Oid relid)
{
	Relation	rel;
	char	   *schema_name;
	bool		result;

	/* relid is InvalidOid */
	if (!OidIsValid(relid))
		return false;

	/* no such relation */
	rel = try_relation_open(relid, NoLock);
	if (rel == NULL)
		return false;

	/* check by namespace name. */
	schema_name = get_namespace_name(rel->rd_rel->relnamespace);
	result = dbms_stats_is_system_schema_internal(schema_name);
	relation_close(rel, NoLock);

	return result;
}

/*
 * dbms_stats_get_relation_info
 *   Hook function for get_relation_info_hook, which implements post-process of
 *   get_relation_info().
 *
 *   This function is designed on the basis of the fact that only expression
 *   indexes have statistics.
 */
static void
dbms_stats_get_relation_info(PlannerInfo *root,
							 Oid relid,
							 bool inhparent,
							 RelOptInfo *rel)
{
	ListCell   *lc;
	double		allvisfrac; /* dummy */

	/*
	 * Call previously installed hook function regardless to whether
	 * pg_dbms_stats is enabled or not.
	 */
	if (prev_get_relation_info)
		prev_get_relation_info(root, relid, inhparent, rel);

	/* If pg_dbms_stats is disabled, there is no more thing to do. */
	if (!pg_dbms_stats_use_locked_stats)
		return;

	/*
	 * Adjust stats of table itself, and stats of index
	 * relation_stats_effective as well
	 */

	/*
	 * Estimate relation size --- unless it's an inheritance parent, in which
	 * case the size will be computed later in set_append_rel_pathlist, and we
	 * must leave it zero for now to avoid bollixing the total_table_pages
	 * calculation.
	 */
	if (!inhparent)
	{
#if PG_VERSION_NUM >= 90200
		get_merged_relation_stats(relid, &rel->pages, &rel->tuples,
								  &rel->allvisfrac, true);
#else
		get_merged_relation_stats(relid, &rel->pages, &rel->tuples,
								  &allvisfrac, true);
#endif
	}
	else
		return;

	foreach(lc, rel->indexlist)
	{
		/*
		 * Estimate the index size.  If it's not a partial index, we lock
		 * the number-of-tuples estimate to equal the parent table; if it
		 * is partial then we have to use the same methods as we would for
		 * a table, except we can be sure that the index is not larger
		 * than the table.
		 */
		IndexOptInfo   *info = (IndexOptInfo *) lfirst(lc);
		bool			estimate = info->indpred != NIL;

		get_merged_relation_stats(info->indexoid, &info->pages, &info->tuples,
								  &allvisfrac, estimate);

		if (!estimate || (estimate && info->tuples > rel->tuples))
			info->tuples = rel->tuples;
	}
}

/*
 * dbms_stats_get_attavgwidth
 *   Hook function for get_attavgwidth_hook which replaces get_attavgwidth().
 *   Returning 0 tells caller to use standard routine.
 */
static int32
dbms_stats_get_attavgwidth(Oid relid, AttrNumber attnum)
{
	if (pg_dbms_stats_use_locked_stats)
	{
		int32	width = get_merged_avgwidth(relid, attnum);
		if (width > 0)
			return width;
	}

	if (prev_get_attavgwidth)
		return prev_get_attavgwidth(relid, attnum);
	else
		return 0;
}

/*
 * We do nothing here, to keep the tuple valid even after examination.
 */
static void
FreeHeapTuple(HeapTuple tuple)
{
	/* noop */
}

/*
 * dbms_stats_get_relation_stats
 *   Hook function for get_relation_stats_hook which provides custom
 *   per-relation statistics.
 *   Returning false tells caller to use standard (true) statistics.
 */
static bool
dbms_stats_get_relation_stats(PlannerInfo *root,
							  RangeTblEntry *rte,
							  AttrNumber attnum,
							  VariableStatData *vardata)
{
	if (pg_dbms_stats_use_locked_stats)
	{
		HeapTuple	tuple;

		tuple = get_merged_column_stats(rte->relid, attnum, rte->inh);
		if (tuple != NULL)
		{
			vardata->statsTuple = tuple;
			vardata->freefunc = FreeHeapTuple;
			return true;
		}
	}

	if (prev_get_relation_stats)
		return prev_get_relation_stats(root, rte, attnum, vardata);
	else
		return false;
}

/*
 * dbms_stats_get_index_stats
 *   Hook function for get_index_stats_hook which provides custom per-relation
 *   statistics.
 *   Returning false tells caller to use standard (true) statistics.
 */
static bool
dbms_stats_get_index_stats(PlannerInfo *root,
						   Oid indexOid,
						   AttrNumber indexattnum,
						   VariableStatData *vardata)
{
	if (pg_dbms_stats_use_locked_stats)
	{
		HeapTuple	tuple;

		tuple = get_merged_column_stats(indexOid, indexattnum, false);
		if (tuple != NULL)
		{
			vardata->statsTuple = tuple;
			vardata->freefunc = FreeHeapTuple;
			return true;
		}
	}

	if (prev_get_index_stats)
		return prev_get_index_stats(root, indexOid, indexattnum, vardata);
	else
		return false;
}

/*
 * Extract binary value from given column.
 */
static Datum
get_binary_datum(int column, bool *isnull)
{
	return SPI_getbinval(SPI_tuptable->vals[0],
						 SPI_tuptable->tupdesc, column, isnull);
}

/*
 * get_merged_relation_stats
 *   get the statistics of the table, # of pages and # of rows, by executing
 *   SELECT against dbms_stats.relation_stats_locked view.
 */
static void
get_merged_relation_stats(Oid relid, BlockNumber *pages, double *tuples,
						  double *allvisfrac, bool estimate)
{
	StatsRelationEntry *entry;
	bool		found;
	Relation	rel;

	/* avoid recursive call and system objects */
	if (nested_level > 0 || relid < FirstNormalObjectId)
		return;

	/*
	 * pg_dbms_stats doesn't handle system catalogs and its internal relation_stats_effective
	 */
	if (dbms_stats_is_system_catalog_internal(relid))
		return;

	/*
	 * First, search from cache.  If we have not cached stats for given relid
	 * yet, initialize newly created entry.
	 */
	entry = hash_search(rel_stats, &relid, HASH_ENTER, &found);
	if (!found)
		init_rel_stats_entry(entry, relid);

	/*
	 * If we don't have valid cache entry, retrieve stats from catalogs,
	 * pg_class and dbms_stats.relation_stats_locked, and merge them for planner use.
	 * We also cache curpages value to make plans stable.
	 */
	if (!entry->valid)
	{
		bool		has_dummy;

		PG_TRY();
		{
			++nested_level;

			SPI_connect();

			/*
			 * Retrieve per-tuple dummy statistics from relation_stats_locked table
			 * via SPI.  If we don't have dummy statistics, we return false to
			 * tell caller thet we gave up to provide alternative statistics.
			 */
			has_dummy = execute_plan(&rows_plan, rows_query, relid, NULL, true);
			if (has_dummy)
			{
				HeapTuple	tuple;
				Form_pg_class form;
				bool		isnull;
				Datum		val;

				/*
				 * Retrieve per-relation stats from pg_class system catalog.
				 * We use syscache to support indexes
				 */
				tuple = SearchSysCache1(RELOID, ObjectIdGetDatum(relid));
				if (!HeapTupleIsValid(tuple))
					elog(ERROR, "cache lookup failed for relation %u", relid);
				form = (Form_pg_class) GETSTRUCT(tuple);

				/* Choose dummy or authentic */
				val = get_binary_datum(1, &isnull);
				entry->relpages = isnull ? form->relpages :
						(BlockNumber) DatumGetInt32(val);
				val = get_binary_datum(2, &isnull);
				entry->reltuples = isnull ? form->reltuples :
						(double) DatumGetFloat4(val);
				val = get_binary_datum(3, &isnull);
				entry->curpages = isnull ? InvalidBlockNumber :
						(BlockNumber) DatumGetInt32(val);
#if PG_VERSION_NUM >= 90200
				val = get_binary_datum(4, &isnull);
				entry->relallvisible = isnull ? form->relallvisible :
						(BlockNumber) DatumGetInt32(val);
#endif

				ReleaseSysCache(tuple);

				/* Mark this entry as valid. */
				entry->valid = true;
			}

			SPI_finish();

			--nested_level;
		}
		PG_CATCH();
		{
			--nested_level;
			PG_RE_THROW();
		}
		PG_END_TRY();

		/*
		 * If we don't dummy statistics, tell caller that we didn't change
		 * stats in Relation, and it's ok to use authentic statistics as-is.
		 */
		if (!has_dummy)
			return;
	}

	if (!estimate)
	{
		*pages = entry->relpages;
		*tuples = entry->reltuples;
		return;
	}

	/*
	 * Get current # of pages to estimate current # of tuples, based on
	 * tuple density at the last ANALYZE and current # of pages.
	 */
	rel = relation_open(relid, NoLock);
	rel->rd_rel->relpages = entry->relpages;
	rel->rd_rel->reltuples = entry->reltuples;
#if PG_VERSION_NUM >= 90200
	rel->rd_rel->relallvisible = entry->relallvisible;
#endif
	dbms_stats_estimate_rel_size(rel, NULL, pages, tuples, allvisfrac,
								 entry->curpages);
	relation_close(rel, NoLock);
}

/*
 * get_merged_avgwidth
 *   get average width of the given column by merging dummy and authentic
 *   statistics
 */
static int32
get_merged_avgwidth(Oid relid, AttrNumber attnum)
{
	HeapTuple		tuple;

	if (nested_level > 0 || relid < FirstNormalObjectId)
		return 0;	/* avoid recursive call and system objects */

	if ((tuple = get_merged_column_stats(relid, attnum, false)) == NULL)
		return 0;

	return get_pg_statistic(tuple)->stawidth;
}

/*
 * get_merged_column_stats
 *   get per-column statistic of given column
 *
 * We cache the result because this function is called for every used column.
 */
static HeapTuple
get_merged_column_stats(Oid relid, AttrNumber attnum, bool inh)
{
	HeapTuple		tuple;
	HeapTuple		statsTuple;

	if (nested_level > 0 || relid < FirstNormalObjectId)
		return NULL;	/* avoid recursive call and system objects */

	/* If the relation is system catalog, return NULL to use true statistics. */
	if (dbms_stats_is_system_catalog_internal(relid))
		return NULL;

	/* Return cached statistics, if any. */
	if ((tuple = column_cache_search(relid, attnum, inh)) != NULL)
		return tuple;

	/* Obtain statistics from syscache.  This must be released afterward. */
	statsTuple = SearchSysCache3(STATRELATTINH,
								 ObjectIdGetDatum(relid),
								 Int16GetDatum(attnum),
								 BoolGetDatum(inh));
	PG_TRY();
	{
		++nested_level;

		SPI_connect();

		/* Obtain dummy statistics. */
		if (execute_plan(&tuple_plan, tuple_query, relid, &attnum, inh))
		{
			/* merge the dummy statistics and the true statistics */
			tuple = dbms_stats_merge_internal(SPI_tuptable->vals[0], statsTuple,
											  SPI_tuptable->tupdesc);
		}
		else
		{
			/* if dummy statistics does not exist, use the true statistics */
			tuple = statsTuple;
		}

		/* Cache merged result for subsequent calls. */
		if (tuple != NULL)
			tuple = column_cache_enter(tuple);

		SPI_finish();

		--nested_level;
	}
	PG_CATCH();
	{
		--nested_level;
		PG_RE_THROW();
	}
	PG_END_TRY();

	if (HeapTupleIsValid(statsTuple))
		ReleaseSysCache(statsTuple);

	return tuple;
}

/*
 * column_cache_search
 *   Search statistic of the given column from the cache.
 */
static HeapTuple
column_cache_search(Oid relid, AttrNumber attnum, bool inh)
{
	StatsRelationEntry *entry;
	bool			found;
	ListCell	   *lc;

	/*
	 * First, get cached relation stats.  If we have not cached relation stats,
	 * we don't have column stats too.
	 */
	entry = hash_search(rel_stats, &relid, HASH_FIND, &found);
	if (!found )
		return NULL;

	/*
	 * It is assumed that not so many column_stats_effective are defined on a relation, so we
	 * use simple linear-search here.  Using hash table for each relation would
	 * be another solution, but it seems overkill so far.
	 */
	foreach(lc, entry->col_stats)
	{
		HeapTuple	tuple = (HeapTuple) lfirst(lc);
		Form_pg_statistic form = get_pg_statistic(tuple);

		/* Find statistic of the given column from the cache. */
		if (form->staattnum == attnum && form->stainherit == inh)
			return tuple;
	}

	return NULL;	/* not found */
}

/*
 * Cache a per-column statistics. Cached statistics are valid through the
 * current session, unless dummy statistics or table definition have been
 * changed.
 *
 * We store statistics tuple in longer-lifetime context, CacheMemoryContext, to
 * keep them alive during this session.
 */
static HeapTuple
column_cache_enter(HeapTuple tuple)
{
	MemoryContext	oldcontext;
	HeapTuple		newtuple;
	Form_pg_statistic form;
	StatsRelationEntry *entry;
	bool			found;

	Assert(tuple != NULL);
	Assert(!heap_attisnull(tuple, 1));

	form = get_pg_statistic(tuple);

	entry = hash_search(rel_stats, &form->starelid, HASH_ENTER, &found);
	if (!found)
		init_rel_stats_entry(entry, form->starelid);

	/*
	 * Link new column statistics entry into the list in relation statsstics
	 * entry.
	 */
	oldcontext = MemoryContextSwitchTo(CacheMemoryContext);
	newtuple = heap_copytuple(tuple);
	entry->col_stats = lappend(entry->col_stats, newtuple);
	MemoryContextSwitchTo(oldcontext);

	return newtuple;
}

/*
 * Execute given plan.  When given plan is NULL, create new plan from given
 * query string, and execute it.  This function can be used only for retrieving
 * statistics of column_stats_effective and relation_stats_effective, because we assume #, types, and order
 * of parameters here.
 */
static bool
execute_plan(SPIPlanPtr *plan,
			 const char *query,
			 Oid relid,
			 const AttrNumber *attnum,
			 bool inh)
{
	int		ret;
	Oid		argtypes[3] = { OIDOID, INT2OID, BOOLOID };
	int		nargs;
	Datum	values[3];
	bool	nulls[3] = { false, false, false };

	nargs = (attnum ? 3 : 1);

	/* When plan is not given, create plan from query string at first. */
	if (*plan == NULL)
	{
		SPIPlanPtr p;
		p = SPI_prepare(query, nargs, argtypes);
		if (p == NULL)
			elog(ERROR, "pg_dbms_stats: SPI_prepare => %d", SPI_result);
		*plan = SPI_saveplan(p);
		SPI_freeplan(p);
	}

	values[0] = ObjectIdGetDatum(relid);
	values[1] = Int16GetDatum(attnum ? *attnum : 0);
	values[2] = BoolGetDatum(inh);

	ret = SPI_execute_plan(*plan, values, nulls, true, 1);
	if (ret != SPI_OK_SELECT)
		elog(ERROR, "pg_dbms_stats: SPI_execute_plan => %d", ret);

	return SPI_processed > 0;
}

/*
 * StatsCacheRelCallback
 *		Relcache inval callback function
 *
 * Invalidate cached statistic info of the given relid, or all cached statistic
 * info if relid == InvalidOid.  We don't complain even when we don't have such
 * statistics.
 *
 * Note: arg is not used.
 */
static void
StatsCacheRelCallback(Datum arg, Oid relid)
{
	HASH_SEQ_STATUS		status;
	StatsRelationEntry *entry;

	hash_seq_init(&status, rel_stats);
	while ((entry = hash_seq_search(&status)) != NULL)
	{
		if (relid == InvalidOid || relid == entry->relid)
		{
			/* Mark the relation entry as INVALID */
			entry->valid = false;

			/* Discard every column statistics */
			list_free_deep(entry->col_stats);
			entry->col_stats = NIL;
		}
	}

	/* We always check throughout the list, so hash_seq_term is not necessary */
}

/*
 * Initialize hash table for per-relation statistics.
 */
static void
init_rel_stats(void)
{
	HTAB	   *hash;
	HASHCTL		ctl;

	/* Prevent double initialization. */
	if (rel_stats != NULL)
		return;

	MemSet(&ctl, 0, sizeof(ctl));
	ctl.keysize = sizeof(Oid);
	ctl.entrysize = sizeof(StatsRelationEntry);
	ctl.hash = oid_hash;
	ctl.hcxt = CacheMemoryContext;
	hash = hash_create("dbms_stats relation statistics cache",
					   MAX_REL_CACHE,
					   &ctl, HASH_ELEM | HASH_CONTEXT);

	rel_stats = hash;
}

/*
 * Initialize newly added cache entry so that it represents an invalid cache
 * entry for given relid.
 */
static void
init_rel_stats_entry(StatsRelationEntry *entry, Oid relid)
{
	entry->relid = relid;
	entry->valid = false;
	entry->relpages = InvalidBlockNumber;
	entry->reltuples = 0.0;
	entry->relallvisible = InvalidBlockNumber;
	entry->curpages = InvalidBlockNumber;
	entry->col_stats = NIL;
}

/*
 * dbms_stats_estimate_rel_size - estimate # pages and # tuples in a table or
 * index
 *
 * We also estimate the fraction of the pages that are marked all-visible in
 * the visibility map, for use in estimation of index-only scans.
 *
 * If attr_widths isn't NULL, it points to the zero-index entry of the
 * relation's attr_widths[] cache; we fill this in if we have need to compute
 * the attribute widths for estimation purposes.
 *
 * Note: This function is copied from plancat.c in core source tree of version
 * 9.2, and customized for pg_dbms_stats.  Changes from orignal one are:
 *   - rename by prefixing dbms_stats_
 *   - add 3 parameters (relpages, reltuples, curpage) to pass dummy curpage
 *     values.
 *   - Get current # of pages only when supplied curpages is InvalidBlockNumber
 *   - get franction of all-visible-pages
 */
static void
dbms_stats_estimate_rel_size(Relation rel, int32 *attr_widths,
							 BlockNumber *pages, double *tuples,
							 double *allvisfrac, BlockNumber curpages)
{
	BlockNumber relpages;
	double		reltuples;
	BlockNumber relallvisible;
	double		density;

	switch (rel->rd_rel->relkind)
	{
		case RELKIND_RELATION:
		case RELKIND_INDEX:
		case RELKIND_TOASTVALUE:
			/* it has storage, ok to call the smgr */
			if (curpages == InvalidBlockNumber)
				curpages = RelationGetNumberOfBlocks(rel);

			/*
			 * HACK: if the relation has never yet been vacuumed, use a
			 * minimum size estimate of 10 pages.  The idea here is to avoid
			 * assuming a newly-created table is really small, even if it
			 * currently is, because that may not be true once some data gets
			 * loaded into it.  Once a vacuum or analyze cycle has been done
			 * on it, it's more reasonable to believe the size is somewhat
			 * stable.
			 *
			 * (Note that this is only an issue if the plan gets cached and
			 * used again after the table has been filled.  What we're trying
			 * to avoid is using a nestloop-type plan on a table that has
			 * grown substantially since the plan was made.  Normally,
			 * autovacuum/autoanalyze will occur once enough inserts have
			 * happened and cause cached-plan invalidation; but that doesn't
			 * happen instantaneously, and it won't happen at all for cases
			 * such as temporary tables.)
			 *
			 * We approximate "never vacuumed" by "has relpages = 0", which
			 * means this will also fire on genuinely empty relation_stats_effective.	Not
			 * great, but fortunately that's a seldom-seen case in the real
			 * world, and it shouldn't degrade the quality of the plan too
			 * much anyway to err in this direction.
			 *
			 * There are two exceptions wherein we don't apply this heuristic.
			 * One is if the table has inheritance children.  Totally empty
			 * parent tables are quite common, so we should be willing to
			 * believe that they are empty.  Also, we don't apply the 10-page
			 * minimum to indexes.
			 */
			if (curpages < 10 &&
				rel->rd_rel->relpages == 0 &&
				!rel->rd_rel->relhassubclass &&
				rel->rd_rel->relkind != RELKIND_INDEX)
				curpages = 10;

			/* report estimated # pages */
			*pages = curpages;
			/* quick exit if rel is clearly empty */
			if (curpages == 0)
			{
				*tuples = 0;
				*allvisfrac = 0;
				break;
			}
			/* coerce values in pg_class to more desirable types */
			relpages = (BlockNumber) rel->rd_rel->relpages;
			reltuples = (double) rel->rd_rel->reltuples;
#if PG_VERSION_NUM >= 90200
			relallvisible = (BlockNumber) rel->rd_rel->relallvisible;
#else
			relallvisible = 0;
#endif
			/*
			 * If it's an index, discount the metapage while estimating the
			 * number of tuples.  This is a kluge because it assumes more than
			 * it ought to about index structure.  Currently it's OK for
			 * btree, hash, and GIN indexes but suspect for GiST indexes.
			 */
			if (rel->rd_rel->relkind == RELKIND_INDEX &&
				relpages > 0)
			{
				curpages--;
				relpages--;
			}

			/* estimate number of tuples from previous tuple density */
			if (relpages > 0)
				density = reltuples / (double) relpages;
			else
			{
				/*
				 * When we have no data because the relation was truncated,
				 * estimate tuple width from attribute datatypes.  We assume
				 * here that the pages are completely full, which is OK for
				 * tables (since they've presumably not been VACUUMed yet) but
				 * is probably an overestimate for indexes.  Fortunately
				 * get_relation_info() can clamp the overestimate to the
				 * parent table's size.
				 *
				 * Note: this code intentionally disregards alignment
				 * considerations, because (a) that would be gilding the lily
				 * considering how crude the estimate is, and (b) it creates
				 * platform dependencies in the default plans which are kind
				 * of a headache for regression testing.
				 */
				int32		tuple_width;

				tuple_width = dbms_stats_get_rel_data_width(rel, attr_widths);
				tuple_width += sizeof(HeapTupleHeaderData);
				tuple_width += sizeof(ItemPointerData);
				/* note: integer division is intentional here */
				density = (BLCKSZ - SizeOfPageHeaderData) / tuple_width;
			}
			*tuples = rint(density * (double) curpages);

			/*
			 * We use relallvisible as-is, rather than scaling it up like we
			 * do for the pages and tuples counts, on the theory that any
			 * pages added since the last VACUUM are most likely not marked
			 * all-visible.  But costsize.c wants it converted to a fraction.
			 */
			if (relallvisible == 0 || curpages <= 0)
				*allvisfrac = 0;
			else if ((double) relallvisible >= curpages)
				*allvisfrac = 1;
			else
				*allvisfrac = (double) relallvisible / curpages;
			break;
		case RELKIND_SEQUENCE:
			/* Sequences always have a known size */
			*pages = 1;
			*tuples = 1;
			*allvisfrac = 0;
			break;
		case RELKIND_FOREIGN_TABLE:
			/* Just use whatever's in pg_class */
			*pages = rel->rd_rel->relpages;
			*tuples = rel->rd_rel->reltuples;
			*allvisfrac = 0;
			break;
		default:
			/* else it has no disk storage; probably shouldn't get here? */
			*pages = 0;
			*tuples = 0;
			*allvisfrac = 0;
			break;
	}
}

/*
 * dbms_stats_get_rel_data_width
 *
 * Estimate the average width of (the data part of) the relation's tuples.
 *
 * If attr_widths isn't NULL, it points to the zero-index entry of the
 * relation's attr_widths[] cache; use and update that cache as appropriate.
 *
 * Currently we ignore dropped column_stats_effective.  Ideally those should be included
 * in the result, but we haven't got any way to get info about them; and
 * since they might be mostly NULLs, treating them as zero-width is not
 * necessarily the wrong thing anyway.
 *
 * Note: This function is copied from plancat.c in core source tree of version
 * 9.2, and just renamed.
 */
static int32
dbms_stats_get_rel_data_width(Relation rel, int32 *attr_widths)
{
	int32		tuple_width = 0;
	int			i;

	for (i = 1; i <= RelationGetNumberOfAttributes(rel); i++)
	{
		Form_pg_attribute att = rel->rd_att->attrs[i - 1];
		int32		item_width;

		if (att->attisdropped)
			continue;

		/* use previously cached data, if any */
		if (attr_widths != NULL && attr_widths[i] > 0)
		{
			tuple_width += attr_widths[i];
			continue;
		}

		/* This should match set_rel_width() in costsize.c */
		item_width = get_attavgwidth(RelationGetRelid(rel), i);
		if (item_width <= 0)
		{
			item_width = get_typavgwidth(att->atttypid, att->atttypmod);
			Assert(item_width > 0);
		}
		if (attr_widths != NULL)
			attr_widths[i] = item_width;
		tuple_width += item_width;
	}

	return tuple_width;
}

#ifdef UNIT_TEST
void test_pg_dbms_stats(int *passed, int *total);
static void test_init_rel_stats(int *passed, int *total);
static void test_init_rel_stats_entry(int *passed, int *total);

void
test_pg_dbms_stats(int *passed, int *total)
{
	int local_passed = 0;
	int local_total = 0;

	elog(WARNING, "==========");

	/* Do tests here */
	test_init_rel_stats(&local_passed, &local_total);
	test_init_rel_stats_entry(&local_passed, &local_total);

	elog(WARNING, "%s %d/%d passed", __FUNCTION__, local_passed, local_total);
	*passed += local_passed;
	*total += local_total;
}

static void
test_init_rel_stats_entry(int *passed, int *total)
{
	int		caseno = 0;
	StatsRelationEntry entry;
	
	/*
	 * *-*-1
	 */
	caseno++;
	init_rel_stats_entry(&entry, 1234);
	if (entry.relid == 1234 &&
		entry.valid == false &&
		entry.relpages == InvalidBlockNumber &&
		entry.reltuples == 0 &&
		entry.relallvisible == InvalidBlockNumber &&
		entry.curpages == InvalidBlockNumber &&
		entry.col_stats == NIL)
	{
		elog(WARNING, "%s-%d ok", __FUNCTION__, caseno);
		(*passed)++;
	}
	else
		elog(WARNING, "%s-%d failed: initialized", __FUNCTION__, caseno);

	(*total) += caseno;
}

static void
test_init_rel_stats(int *passed, int *total)
{
	int			caseno = 0;
	static HTAB	   *org_rel_stats;

	/*
	 * *-*-1
	 *   - first call
	 */
	caseno++;
	init_rel_stats();
	if (rel_stats != NULL)
	{
		elog(WARNING, "%s-%d ok", __FUNCTION__, caseno);
		(*passed)++;
	}
	else
		elog(WARNING, "%s-%d failed: rel_stats is NULL", __FUNCTION__, caseno);

	/*
	 * *-*-2
	 *   - second call
	 */
	caseno++;
	org_rel_stats = rel_stats;
	init_rel_stats();
	if (org_rel_stats == rel_stats)
	{
		elog(WARNING, "%s-%d ok", __FUNCTION__, caseno);
		(*passed)++;
	}
	else
		elog(WARNING, "%s-%d failed: rel_stats changed from %p to %p",
			 __FUNCTION__, caseno, org_rel_stats, rel_stats);

	*total += caseno;
}
#endif
