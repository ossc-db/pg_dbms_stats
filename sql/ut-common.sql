\pset null '(null)'
\set SHOW_CONTEXT never
/*
 * No.2-3 dbms_stats.backup_history_id_seq
 */
-- No.2-3-1
SELECT setval('dbms_stats.backup_history_id_seq', 0, false);
-- No.2-3-2
SELECT setval('dbms_stats.backup_history_id_seq', 1, false);
INSERT INTO dbms_stats.backup_history(time, unit)
    VALUES ('2011-01-01', 't');
SELECT id, time, unit FROM dbms_stats.backup_history
 ORDER BY id;
-- No.2-3-3
INSERT INTO dbms_stats.backup_history(time, unit)
    VALUES ('2011-01-02', 'c'), ('2011-01-03', 'd');
SELECT id, time, unit FROM dbms_stats.backup_history
 ORDER BY id;
-- clean up
SELECT setval('dbms_stats.backup_history_id_seq', 1, false);
DELETE FROM dbms_stats.backup_history;

/*
 * No.3-1 dbms_stats.use_locked_stats
 */
DELETE FROM dbms_stats.relation_stats_locked;
EXPLAIN (costs false) SELECT * FROM s0.st2 WHERE id < 1;
SELECT dbms_stats.lock_table_stats('s0.st2'::regclass);
UPDATE dbms_stats.relation_stats_locked SET curpages = 10000;
VACUUM ANALYZE;
-- No.3-1-1
SET pg_dbms_stats.use_locked_stats TO ON;
EXPLAIN (costs false) SELECT * FROM s0.st2 WHERE id < 1;
-- No.3-1-2
SET pg_dbms_stats.use_locked_stats TO OFF;
EXPLAIN (costs false) SELECT * FROM s0.st2 WHERE id < 1;
-- No.3-1-3
/* Reconnection as regular user */
\c - regular_user
SHOW pg_dbms_stats.use_locked_stats;
SET pg_dbms_stats.use_locked_stats TO OFF;
SHOW pg_dbms_stats.use_locked_stats;
EXPLAIN (costs false) SELECT * FROM s0.st2 WHERE id < 1;
RESET pg_dbms_stats.use_locked_stats;
EXPLAIN (costs false) SELECT * FROM s0.st2 WHERE id < 1;
-- clean up
/* Reconnection as super user */
\c - super_user
DELETE FROM dbms_stats.relation_stats_locked;

/*
 * No.4-1 DATA TYPE dbms_stats.anyarray
 */
CREATE TABLE st3(id integer, name char(1000), num_arr char(5)[]);
INSERT INTO st3 SELECT i, i , ARRAY[i::char, 'a'] FROM generate_series(1,10) g(i);
ANALYZE st3;
SELECT staattnum, stavalues1 FROM pg_statistic
 WHERE starelid = 'public.st3'::regclass
 ORDER BY staattnum;
\copy (SELECT stavalues1::dbms_stats.anyarray FROM dbms_stats.column_stats_effective WHERE starelid = 'st3'::regclass ORDER BY staattnum) TO 'results/anyarray_test.cp' binary
SET client_min_messages TO WARNING;
CREATE TABLE st4 (arr dbms_stats.anyarray, ord serial);
SET client_min_messages TO DEFAULT;

SELECT t.typname, n.nspname,
       t.typlen, t.typbyval, t.typtype,
       t.typcategory, t.typispreferred, t.typispreferred,
       t.typdelim, t.typrelid, t.typmodin,
       t.typmodout, t.typanalyze, t.typalign,
       t.typstorage, t.typnotnull, t.typbasetype, t.typtypmod,
       t.typndims, t.typcollation, t.typdefaultbin, t.typdefault
  FROM pg_type t, pg_namespace n
 WHERE t.typname = 'anyarray'
   AND t.typnamespace = n.oid
 ORDER BY t.typname;
-- No.4-1-1
INSERT INTO st4 VALUES(NULL);
SELECT * FROM st4 ORDER BY ord;
-- No.4-1-2
DELETE FROM st4;
SELECT stavalues1::dbms_stats.anyarray
  FROM dbms_stats.column_stats_effective
 WHERE starelid = 'st3'::regclass
   AND staattnum = 1;
SELECT count(*) FROM st4;
INSERT INTO st4
     SELECT stavalues1::dbms_stats.anyarray
       FROM dbms_stats.column_stats_effective
      WHERE starelid = 'st3'::regclass
        AND staattnum = 1;
SELECT * FROM st4 ORDER BY ord;
-- No.4-1-3
DELETE FROM st4;
SELECT stavalues1::dbms_stats.anyarray
  FROM dbms_stats.column_stats_effective
 WHERE starelid = 'st3'::regclass
   AND staattnum = 2;
SELECT count(*) FROM st4;
INSERT INTO st4
     SELECT stavalues1::dbms_stats.anyarray
       FROM dbms_stats.column_stats_effective
      WHERE starelid = 'st3'::regclass
        AND staattnum = 2;
SELECT * FROM st4 ORDER BY ord;
-- No.4-1-4
DELETE FROM st4;
SELECT stavalues1::dbms_stats.anyarray
  FROM dbms_stats.column_stats_effective
 WHERE starelid = 'st3'::regclass
   AND staattnum = 1;
SELECT count(*) FROM st4;
INSERT INTO st4
     SELECT stavalues1::dbms_stats.anyarray
       FROM dbms_stats.column_stats_effective
      WHERE starelid = 'st3'::regclass
        AND staattnum = 1;
SELECT * FROM st4 ORDER BY ord;
-- No.4-1-5
DELETE FROM st4;
SELECT stavalues1::dbms_stats.anyarray
  FROM dbms_stats.column_stats_effective
 WHERE starelid = 'st3'::regclass
   AND staattnum = 3;
SELECT count(*) FROM st4;
INSERT INTO st4
     SELECT stavalues1::dbms_stats.anyarray
       FROM dbms_stats.column_stats_effective
      WHERE starelid = 'st3'::regclass
        AND staattnum = 3;
SELECT * FROM st4 ORDER BY ord;
-- No.4-1-6
DELETE FROM st4;
SELECT stavalues1::dbms_stats.anyarray
  FROM dbms_stats.column_stats_effective
 WHERE starelid = 'st3'::regclass
 ORDER BY staattnum;
\copy st4(arr) FROM 'results/anyarray_test.cp' binary
SELECT * FROM st4 ORDER BY ord;
-- clean up
DROP TABLE st3;
DROP TABLE st4;

SELECT dbms_stats.unlock_database_stats();
SELECT dbms_stats.lock_table_stats('st1');

/*
 * No.5-2 invalid calls of dbms_stats.invalidate_column_cache
 */
-- No.5-2-1
SELECT dbms_stats.invalidate_column_cache();

-- No.5-2-2
/*
 * Driver function dbms_stats.invalidate_cache1
 */
CREATE TRIGGER invalidate_cache1
 AFTER INSERT OR DELETE OR UPDATE
    ON pt0
   FOR EACH ROW EXECUTE PROCEDURE dbms_stats.invalidate_column_cache();
INSERT INTO pt0 VALUES (1,'2012/12/12');
DROP TRIGGER invalidate_cache1 ON pt0;

-- No.5-2-3
/*
 * Driver function dbms_stats.invalidate_cache2
 */
CREATE TRIGGER invalidate_cache2
BEFORE INSERT OR DELETE OR UPDATE
    ON pt0
   FOR EACH STATEMENT EXECUTE PROCEDURE dbms_stats.invalidate_column_cache();
INSERT INTO pt0 VALUES (1,'2012/12/12');
DROP TRIGGER invalidate_cache2 ON pt0;

-- No.5-2-4
/*
 * Driver function dbms_stats.invalidate_cache3
 */
CREATE TRIGGER invalidate_cache3
BEFORE TRUNCATE
    ON pt0
   FOR EACH STATEMENT EXECUTE PROCEDURE dbms_stats.invalidate_column_cache();
TRUNCATE TABLE pt0;
DROP TRIGGER invalidate_cache3 ON pt0;

-- No.5-2-5
EXPLAIN (costs false) SELECT * FROM st1 WHERE val IS NULL;
INSERT INTO dbms_stats.relation_stats_locked (relid, relname) VALUES (0, 'dummy');
INSERT INTO dbms_stats.column_stats_locked (starelid, staattnum, stainherit)
    VALUES (0, 1, true);
EXPLAIN (costs false) SELECT * FROM st1 WHERE val IS NULL;

-- No.5-2-6
INSERT INTO dbms_stats.column_stats_locked (starelid, staattnum, stainherit)
    VALUES ('st1_idx'::regclass, 1, true);
EXPLAIN (costs false) SELECT * FROM st1 WHERE val IS NULL;

-- No.5-2-7
INSERT INTO dbms_stats.column_stats_locked (starelid, staattnum, stainherit)
    VALUES ('complex'::regclass, 1, true);
EXPLAIN (costs false) SELECT * FROM st1 WHERE val IS NULL;

-- No.5-2-9
UPDATE dbms_stats.column_stats_locked SET stanullfrac = 1
 WHERE starelid = 'st1'::regclass
   AND staattnum = 1
   AND stainherit = false;
VACUUM ANALYZE;
EXPLAIN (costs false) SELECT * FROM st1 WHERE val IS NULL;

-- No.5-2-10
DELETE FROM dbms_stats.column_stats_locked
 WHERE starelid = 'st1'::regclass
   AND staattnum = 1
   AND stainherit = false;
EXPLAIN (costs false) SELECT * FROM st1 WHERE val IS NULL;

-- No.5-2-8
INSERT INTO dbms_stats.column_stats_locked
    (starelid, staattnum, stainherit, stanullfrac)
    VALUES ('st1'::regclass, 1, false, 1);
EXPLAIN (costs false) SELECT * FROM st1 WHERE val IS NULL;

-- No.5-2-11
PREPARE p2 AS SELECT str FROM st1 WHERE lower(str) IS NULL;
EXPLAIN (costs false) SELECT str FROM st1 WHERE lower(str) IS NULL;
EXPLAIN (costs false) EXECUTE p2;
INSERT INTO dbms_stats.relation_stats_locked (relid, relname)
    VALUES ('st1_exp'::regclass, 'dummy');
INSERT INTO dbms_stats.column_stats_locked
    (starelid, staattnum, stainherit, stanullfrac)
    VALUES ('st1_exp'::regclass, 1, false, 1);
EXPLAIN (costs false) SELECT str FROM st1 WHERE lower(str) IS NULL;
EXPLAIN (costs false) EXECUTE p2;

DEALLOCATE p2;

SELECT dbms_stats.unlock_database_stats();


/*
 * No.5-3 dbms_stats.invalidate_relation_cache
 */
-- No.5-3-1
SELECT dbms_stats.invalidate_relation_cache();

-- No.5-3-2
/*
 * Driver function dbms_stats.invalidate_cache1
 */
CREATE TRIGGER invalidate_cache1
 AFTER INSERT OR DELETE OR UPDATE
    ON pt0
   FOR EACH ROW EXECUTE PROCEDURE dbms_stats.invalidate_relation_cache();
INSERT INTO pt0 VALUES (1,'2012/12/12');
DROP TRIGGER invalidate_cache1 ON pt0;

-- No.5-3-3
/*
 * Driver function dbms_stats.invalidate_cache2
 */
CREATE TRIGGER invalidate_cache2
BEFORE INSERT OR DELETE OR UPDATE
    ON pt0
   FOR EACH STATEMENT EXECUTE PROCEDURE dbms_stats.invalidate_relation_cache();
INSERT INTO pt0 VALUES (1,'2012/12/12');
DROP TRIGGER invalidate_cache2 ON pt0;

-- No.5-3-4
/*
 * Driver function dbms_stats.invalidate_cache3
 */
CREATE TRIGGER invalidate_cache3
BEFORE TRUNCATE
    ON pt0
   FOR EACH STATEMENT EXECUTE PROCEDURE dbms_stats.invalidate_relation_cache();
TRUNCATE TABLE pt0;
DROP TRIGGER invalidate_cache3 ON pt0;

-- No.5-3-5
SELECT dbms_stats.unlock_database_stats();
SELECT dbms_stats.lock_table_stats('st1');
EXPLAIN (costs false) SELECT * FROM st1 WHERE val IS NULL;
INSERT INTO dbms_stats.relation_stats_locked (relid, relname) VALUES (0, 'dummy');
EXPLAIN (costs false) SELECT * FROM st1 WHERE val IS NULL;

-- No.5-3-6
EXPLAIN (costs false) SELECT * FROM st1 WHERE val IS NULL;
INSERT INTO dbms_stats.relation_stats_locked (relid, relname)
    VALUES ('st1_idx'::regclass, 'st1_idx');
EXPLAIN (costs false) SELECT * FROM st1 WHERE val IS NULL;

-- No.5-3-7
EXPLAIN (costs false) SELECT * FROM st1 WHERE val IS NULL;
INSERT INTO dbms_stats.relation_stats_locked (relid, relname)
    VALUES ('complex'::regclass, 'complex');
EXPLAIN (costs false) SELECT * FROM st1 WHERE val IS NULL;

-- No.5-3-9
EXPLAIN (costs false) SELECT * FROM st1 WHERE val IS NULL;
UPDATE dbms_stats.relation_stats_locked SET curpages = 1
 WHERE relid = 'st1'::regclass;
VACUUM ANALYZE;
EXPLAIN (costs false) SELECT * FROM st1 WHERE val IS NULL;

-- No.5-3-10
EXPLAIN (costs false) SELECT * FROM st1 WHERE val IS NULL;
DELETE FROM dbms_stats.relation_stats_locked
 WHERE relid = 'st1'::regclass;
EXPLAIN (costs false) SELECT * FROM st1 WHERE val IS NULL;

-- No.5-3-8
EXPLAIN (costs false) SELECT * FROM st1 WHERE val IS NULL;
INSERT INTO dbms_stats.relation_stats_locked (relid, relname, curpages)
    VALUES ('st1'::regclass, 'st1', 1);
EXPLAIN (costs false) SELECT * FROM st1 WHERE val IS NULL;

-- No.5-3-11
SELECT dbms_stats.unlock_database_stats();
SELECT dbms_stats.lock_table_stats('st1');
SELECT relname, curpages FROM dbms_stats.relation_stats_locked
 WHERE relid = 'st1'::regclass;
SELECT pg_sleep(0.7);
SELECT load_merged_stats();
SELECT pg_stat_reset();
VACUUM ANALYZE;
UPDATE dbms_stats.relation_stats_locked SET curpages = 1000
 WHERE relid = 'st1_exp'::regclass;
SELECT pg_sleep(0.7);
SELECT * FROM lockd_io;
SELECT load_merged_stats();
SELECT pg_stat_reset();
SELECT relname, curpages FROM dbms_stats.relation_stats_locked
 WHERE relid = 'st1'::regclass;
SELECT pg_sleep(0.7);
SELECT * FROM lockd_io;

/*
 * No.5-4 StatsCacheRelCallback
 */
-- No.5-4-1
UPDATE dbms_stats.relation_stats_locked SET curpages = 1
 WHERE relid = 'st1'::regclass;
VACUUM ANALYZE;
EXPLAIN (costs false) SELECT * FROM st1 WHERE val IS NULL;
\c
SET pg_dbms_stats.use_locked_stats to NO;
EXPLAIN (costs false) SELECT * FROM st1 WHERE val IS NULL;
SET pg_dbms_stats.use_locked_stats to YES;
EXPLAIN (costs false) SELECT * FROM st1 WHERE val IS NULL;

SELECT dbms_stats.unlock_database_stats();
SELECT dbms_stats.lock_table_stats('st1');
-- No.5-4-3
EXPLAIN (costs false) SELECT * FROM st1 WHERE val IS NULL;
\! psql contrib_regression -c "UPDATE dbms_stats.column_stats_locked SET stanullfrac = 1 WHERE starelid = 'st1'::regclass"
EXPLAIN (costs false) SELECT * FROM st1 WHERE val IS NULL;

-- No.5-4-4
EXPLAIN (costs false) SELECT * FROM st1 WHERE val IS NULL;
\! psql contrib_regression -c "DELETE FROM dbms_stats.column_stats_locked WHERE starelid = 'st1'::regclass"
EXPLAIN (costs false) SELECT * FROM st1 WHERE val IS NULL;

-- No.5-4-2
EXPLAIN (costs false) SELECT * FROM st1 WHERE val IS NULL;
\! psql contrib_regression -c "INSERT INTO dbms_stats.column_stats_locked (starelid, staattnum, stainherit, stanullfrac) VALUES ('st1'::regclass, 1, false, 1)"
EXPLAIN (costs false) SELECT * FROM st1 WHERE val IS NULL;

SELECT dbms_stats.unlock_database_stats();

-- No.5-4-5
CREATE TABLE s0.droptest(id integer);
INSERT INTO s0.droptest VALUES (1),(2),(3);
VACUUM ANALYZE;
SELECT * FROM s0.droptest
 WHERE id = 1;
SELECT pg_sleep(0.7);
SELECT load_merged_stats();
SELECT pg_stat_reset();
ALTER TABLE s0.droptest RENAME TO test;
SELECT pg_sleep(0.7);
SELECT * FROM lockd_io;
SELECT load_merged_stats();
SELECT pg_stat_reset();
SELECT * FROM s0.test
 WHERE id = 1;
SELECT pg_sleep(0.7);
SELECT * FROM lockd_io;
ALTER TABLE s0.test RENAME TO droptest;

-- No.5-4-6
VACUUM ANALYZE;
SELECT * FROM s0.droptest
 WHERE id = 1;
SELECT pg_sleep(0.7);
SELECT load_merged_stats();
SELECT pg_stat_reset();
ALTER TABLE s0.droptest RENAME id TO test;
SELECT pg_sleep(0.7);
SELECT * FROM lockd_io;
SELECT load_merged_stats();
SELECT pg_stat_reset();
SELECT * FROM s0.droptest
 WHERE test = 1;
SELECT pg_sleep(0.7);
SELECT * FROM lockd_io;
ALTER TABLE s0.droptest RENAME test TO id;

-- No.5-4-8
INSERT INTO s0.droptest VALUES (4);
SELECT * FROM s0.droptest
 WHERE id = 1;
SELECT pg_sleep(0.7);
SELECT load_merged_stats();
SELECT pg_stat_reset();
ANALYZE;
SELECT pg_sleep(0.7);
SELECT * FROM lockd_io;
SELECT load_merged_stats();
SELECT pg_stat_reset();
SELECT * FROM s0.droptest
 WHERE id = 1;
SELECT pg_sleep(1.0);
SELECT * FROM lockd_io;

-- No.5-4-9
DELETE FROM s0.droptest;
INSERT INTO s0.droptest VALUES (4),(5);
SELECT * FROM s0.droptest
 WHERE id = 4;
SELECT pg_sleep(0.7);
SELECT load_merged_stats();
SELECT pg_stat_reset();
VACUUM ANALYZE;
SELECT pg_sleep(0.7);
SELECT * FROM lockd_io;
SELECT load_merged_stats();
SELECT pg_stat_reset();
SELECT * FROM s0.droptest
 WHERE id = 4;
SELECT pg_sleep(0.7);
SELECT * FROM lockd_io;

-- clean up
DROP TABLE s0.droptest;

/*
 * No.6-1 dbms_stats.relname
 */
-- No.6-1-1
SELECT dbms_stats.relname('aaa', 'bbb');
-- No.6-1-2
SELECT dbms_stats.relname(NULL, 'bbb');
-- No.6-1-3
SELECT dbms_stats.relname('aaa', NULL);
-- No.6-1-4
SELECT dbms_stats.relname(NULL, NULL);
-- No.6-1-5
SELECT dbms_stats.relname('', '');
-- No.6-1-6
SELECT dbms_stats.relname('aAa', 'bBb');
-- No.6-1-7
SELECT dbms_stats.relname('a a', 'b b');
-- No.6-1-8
SELECT dbms_stats.relname('a.a', 'b.b');
-- No.6-1-9
SELECT dbms_stats.relname(E'a\na', E'b\nb');
-- No.6-1-10
SELECT dbms_stats.relname('a"a', 'b"b');
-- No.6-1-11
SELECT dbms_stats.relname('あいう', '亞伊卯');

/*
 * No.6-2 dbms_stats.is_system_schema
 */
-- No.6-2-1
SELECT dbms_stats.is_system_schema('pg_catalog');
-- No.6-2-2
SELECT dbms_stats.is_system_schema('pg_toast');
-- No.6-2-3
SELECT dbms_stats.is_system_schema('information_schema');
-- No.6-2-4
SELECT dbms_stats.is_system_schema('dbms_stats');
-- No.6-2-5
SELECT dbms_stats.is_system_schema(NULL);
-- No.6-2-6
SELECT dbms_stats.is_system_schema('');
-- No.6-2-7
SELECT dbms_stats.is_system_schema('s0');
-- No.6-2-8
/*
 * Driver function dbms_stats.is_system_schema1
 */
CREATE FUNCTION dbms_stats.is_system_schema1(schemaname text)
 RETURNS integer AS
 '$libdir/pg_dbms_stats', 'dbms_stats_is_system_schema'
 LANGUAGE C IMMUTABLE STRICT;
SELECT dbms_stats.is_system_schema1('s0');
DROP FUNCTION dbms_stats.is_system_schema1(schemaname text);

/*
 * No.6-3 dbms_stats.is_system_catalog
 */
-- No.6-3-1
SELECT dbms_stats.is_system_catalog('s0.st0');
-- No.6-3-2
SELECT dbms_stats.is_system_catalog('st0');
-- No.6-3-3
SELECT dbms_stats.is_system_catalog('s00.s0');
-- No.6-3-4
SELECT dbms_stats.is_system_catalog(NULL);
-- No.6-3-5
/*
 * Driver function dbms_stats.is_system_catalog1
 */
CREATE FUNCTION dbms_stats.is_system_catalog1(relid regclass)
RETURNS integer AS
'$libdir/pg_dbms_stats', 'dbms_stats_is_system_catalog'
LANGUAGE C STABLE;
SELECT dbms_stats.is_system_catalog1('s0.st0');
DROP FUNCTION dbms_stats.is_system_catalog1(relid regclass);


/*
 * No.6-4 dbms_stats.is_target_relkind
 */
-- No.6-4-1
SELECT dbms_stats.is_target_relkind('r');
-- No.6-4-2
SELECT dbms_stats.is_target_relkind('i');
-- No.6-4-3
SELECT dbms_stats.is_target_relkind('S');
-- No.6-4-4
SELECT dbms_stats.is_target_relkind('v');
-- No.6-4-5
SELECT dbms_stats.is_target_relkind('c');
-- No.6-4-6
SELECT dbms_stats.is_target_relkind('t');
-- No.6-4-7
SELECT dbms_stats.is_target_relkind('a');
-- No.6-4-8
SELECT dbms_stats.is_target_relkind('');
-- No.6-4-9
SELECT dbms_stats.is_target_relkind(NULL);
--#No.6-4-10 result varies according to a version
--#No.6-4-11 result varies according to a version

/*
 * No.7-1 dbms_stats.backup
 */
INSERT INTO dbms_stats.backup_history(id, time, unit) values(1, '2012-01-01', 'd');
-- No.7-1-1
DELETE FROM dbms_stats.relation_stats_backup;
SELECT dbms_stats.backup(1, 's0.st0'::regclass, NULL);
SELECT relid::regclass FROM dbms_stats.relation_stats_backup
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, staattnum FROM dbms_stats.column_stats_backup
 GROUP BY starelid, staattnum
 ORDER BY starelid, staattnum;

-- No.7-1-2
DELETE FROM dbms_stats.relation_stats_backup;
SELECT dbms_stats.backup(1, 'st0'::regclass, NULL);
SELECT relid::regclass FROM dbms_stats.relation_stats_backup
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, staattnum FROM dbms_stats.column_stats_backup
 GROUP BY starelid, staattnum
 ORDER BY starelid, staattnum;

-- No.7-1-3
DELETE FROM dbms_stats.relation_stats_backup;
SELECT dbms_stats.backup(1, 'public.notfound'::regclass, NULL);
SELECT count(*) FROM dbms_stats.relation_stats_backup;
SELECT count(*) FROM dbms_stats.column_stats_backup;

-- No.7-1-4
DELETE FROM dbms_stats.relation_stats_backup;
SELECT dbms_stats.backup(1, 's0.st0'::regclass, NULL);
SELECT relid::regclass FROM dbms_stats.relation_stats_backup
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, staattnum FROM dbms_stats.column_stats_backup
 GROUP BY starelid, staattnum
 ORDER BY starelid, staattnum;

-- No.7-1-5
DELETE FROM dbms_stats.relation_stats_backup;
SELECT dbms_stats.backup(1, 'pg_toast.pg_toast_2618'::regclass, NULL);
SELECT relid::regclass FROM dbms_stats.relation_stats_backup
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, staattnum FROM dbms_stats.column_stats_backup
 GROUP BY starelid, staattnum
 ORDER BY starelid, staattnum;

-- No.7-1-6
DELETE FROM dbms_stats.relation_stats_backup;
SELECT dbms_stats.backup(1, 's0.st0_idx'::regclass, NULL);
SELECT relid::regclass FROM dbms_stats.relation_stats_backup
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, staattnum FROM dbms_stats.column_stats_backup
 GROUP BY starelid, staattnum
 ORDER BY starelid, staattnum;

-- No.7-1-7
DELETE FROM dbms_stats.relation_stats_backup;
SELECT dbms_stats.backup(1, 's0.ss0'::regclass, NULL);
SELECT count(*) FROM dbms_stats.relation_stats_backup;
SELECT count(*) FROM dbms_stats.column_stats_backup;

-- No.7-1-8
DELETE FROM dbms_stats.relation_stats_backup;
SELECT dbms_stats.backup(1, 's0.sc0'::regclass, NULL);
SELECT count(*) FROM dbms_stats.relation_stats_backup;
SELECT count(*) FROM dbms_stats.column_stats_backup;

--#No.7-1-9 ut-<PG Version>
--#No.7-1-10 ut-<PG Version>

-- No.7-1-11
DELETE FROM dbms_stats.relation_stats_backup;
SELECT dbms_stats.backup(1, 's0.st0'::regclass, 1::int2);
SELECT relid::regclass FROM dbms_stats.relation_stats_backup
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, staattnum FROM dbms_stats.column_stats_backup
 GROUP BY starelid, staattnum
 ORDER BY starelid, staattnum;

--#No.7-1-12 ut-<PG Version>

-- No.7-1-13
DELETE FROM dbms_stats.relation_stats_backup;
SELECT dbms_stats.backup(1, 's0.st0'::regclass, NULL);
SELECT relid::regclass FROM dbms_stats.relation_stats_backup
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, staattnum FROM dbms_stats.column_stats_backup
 GROUP BY starelid, staattnum
 ORDER BY starelid, staattnum;

--#No.7-1-14 ut-<PG Version>

-- No.7-1-15
DELETE FROM dbms_stats.relation_stats_backup;
SELECT dbms_stats.backup(1, 'pg_catalog.pg_class'::regclass, NULL);
SELECT count(*) FROM dbms_stats.relation_stats_backup;
SELECT count(*) FROM dbms_stats.column_stats_backup;

-- No.7-1-16
SELECT dbms_stats.backup(1, 's0.st0'::regclass, NULL);
DELETE FROM dbms_stats.column_stats_backup;
SELECT starelid::regclass, staattnum FROM dbms_stats.column_stats_backup
 GROUP BY starelid, staattnum
 ORDER BY starelid, staattnum;
SELECT count(*) FROM dbms_stats.relation_stats_backup;
-- SELECT dbms_stats.backup(1, 's0.st0'::regclass, NULL);
-- To avoid test unstability caused by relation id allocation, unique
-- constraint which used to be checked above is now checked more
-- directly in the following step.
SELECT ic.relname idxname, i.indisprimary
 FROM pg_index i
 JOIN pg_class c ON (c.oid = i.indrelid)
 JOIN pg_namespace n ON (n.oid = c.relnamespace)
 JOIN pg_class ic ON (ic.oid = i.indexrelid)
 WHERE n.nspname = 'dbms_stats' AND c.relname = 'relation_stats_backup';
SELECT count(*) FROM dbms_stats.relation_stats_backup;
SELECT count(*) FROM dbms_stats.column_stats_backup;

--#No.7-1-18 ut-<PG Version>

/*
 * Stab function dbms_stats.backup
 */
ALTER FUNCTION dbms_stats.backup(
    backup_id int8,
    relid regclass,
    attnum int2)
    RENAME TO truth_func_backup;

CREATE OR REPLACE FUNCTION dbms_stats.backup(
    backup_id int8,
    regclass,
    attnum int2)
RETURNS int8 AS
$$
BEGIN
    RAISE NOTICE 'arguments are %, %, %', $1, $2, $3;
    RETURN 1;
END;
$$
LANGUAGE plpgsql;

ALTER FUNCTION dbms_stats.backup(
    relid regclass,
    attname text,
    comment text)
    RENAME TO truth_func_backup;
CREATE OR REPLACE FUNCTION dbms_stats.backup(
    relid regclass DEFAULT NULL,
    attname text DEFAULT NULL,
    comment text DEFAULT NULL)
RETURNS int8 AS
$$
BEGIN
    IF $3 = '<NULL>' THEN
        RAISE NOTICE 'third argument is not NULL but string "<NULL>"';
    END IF;
    RAISE NOTICE 'arguments are %, %, %', $1, $2, $3;
    RETURN 1;
END;
$$
LANGUAGE plpgsql;

/*
 * No.8-2 dbms_stats.backup_database_stats
 */
SELECT setval('dbms_stats.backup_history_id_seq',8);
-- No.8-2-1
SELECT dbms_stats.backup_database_stats('comment');

/*
 * No.8-4 dbms_stats.backup_table_stats(regclass,comment)
 */
-- No.8-4-1
SELECT dbms_stats.backup_table_stats('s0.st0', 'comment');
-- No.8-4-2
SELECT dbms_stats.backup_table_stats('st0', 'comment');
-- No.8-4-3
SELECT dbms_stats.backup_table_stats('s00.s0', 'comment');

/*
 * No.8-5 dbms_stats.backup_table_stats(schemaname, tablename, comment)
 */
-- No.8-5-1
SELECT dbms_stats.backup_table_stats('s0', 'st0', 'comment');
-- No.8-5-2
SELECT dbms_stats.backup_table_stats('s00', 's0', 'comment');

/*
 * No.8-6 dbms_stats.backup_column_stats(regclass, attname, comment)
 */
-- No.8-6-1
SELECT dbms_stats.backup_column_stats('s0.st0', 'id', 'comment');
-- No.8-6-2
SELECT dbms_stats.backup_column_stats('st0', 'id', 'comment');
-- No.8-6-3
SELECT dbms_stats.backup_column_stats('s00.s0', 'id', 'comment');

/*
 * No.8-7 dbms_stats.backup_column_stats(schemaname, tablename, attname, comment)
 */
-- No.8-7-1
SELECT dbms_stats.backup_column_stats('s0', 'st0', 'id', 'comment');
-- No.8-7-2
SELECT dbms_stats.backup_column_stats('s00', 's0', 'id', 'comment');

/*
 * Delete stab function dbms_stats.backup
 */
DROP FUNCTION dbms_stats.backup(
    backup_id int8,
    regclass,
    attnum int2);
ALTER FUNCTION dbms_stats.truth_func_backup(
    backup_id int8,
    regclass,
    attnum int2)
    RENAME TO backup;
DROP FUNCTION dbms_stats.backup(
    regclass,
    attname text,
    comment text);
ALTER FUNCTION dbms_stats.truth_func_backup(
    regclass,
    attname text,
    comment text)
    RENAME TO backup;
VACUUM ANALYZE;

/*
 * create backup statistics state A
 */
DELETE FROM dbms_stats.backup_history;

INSERT INTO dbms_stats.backup_history(id, time, unit)
    VALUES (1, '2012-02-29 23:59:56.999999', 'd');

SELECT setval('dbms_stats.backup_history_id_seq',1);
SELECT dbms_stats.backup();
UPDATE dbms_stats.backup_history
   SET time = '2012-02-29 23:59:57'
 WHERE id = 2;
SELECT dbms_stats.backup('s0.st0');
UPDATE dbms_stats.backup_history
   SET time = '2012-02-29 23:59:57.000001'
 WHERE id = 3;
SELECT dbms_stats.backup();
UPDATE dbms_stats.backup_history
   SET time = '2012-02-29 23:59:58'
 WHERE id = 4;
DELETE FROM dbms_stats.relation_stats_backup
 WHERE id = 4;
SELECT dbms_stats.backup('s0.st0', 'id');
UPDATE dbms_stats.backup_history
   SET time = '2012-03-01 00:00:00'
 WHERE id = 5;
SELECT dbms_stats.backup('s0.st0');
UPDATE dbms_stats.backup_history
   SET time = '2012-03-01 00:00:02'
 WHERE id = 6;
SELECT dbms_stats.backup('public.st0');
UPDATE dbms_stats.backup_history
   SET time = '2012-03-01 00:00:04'
 WHERE id = 7;
INSERT INTO dbms_stats.backup_history(time, unit)
    VALUES ('2012-03-01 00:00:06', 's');
SELECT dbms_stats.backup(8, c.oid, NULL)
  FROM pg_catalog.pg_class c,
       pg_catalog.pg_namespace n
 WHERE n.nspname = 's0'
   AND c.relnamespace = n.oid
   AND c.relkind IN ('r', 'i');

SELECT * FROM dbms_stats.backup_history
 ORDER BY id;

VACUUM ANALYZE;

/*
 * Stab function dbms_stats.restore
 */
ALTER FUNCTION dbms_stats.restore(int8, regclass, text)
      RENAME TO truth_func_restore;
CREATE FUNCTION dbms_stats.restore(int8, regclass DEFAULT NULL, text DEFAULT NULL)
RETURNS SETOF regclass AS
$$
BEGIN
    RAISE NOTICE 'arguments are "%, %, %"', $1, $2, $3;
    RETURN QUERY
        SELECT c.oid::regclass
          FROM pg_class c, dbms_stats.relation_stats_backup b
         WHERE (c.oid = $2 OR $2 IS NULL)
           AND c.oid = b.relid
           AND c.relkind IN ('r', 'i')
           AND (b.id <= $1 OR $1 IS NOT NULL)
         GROUP BY c.oid
         ORDER BY c.oid::regclass::text;
END;
$$
LANGUAGE plpgsql;

/*
 * No.10-3 dbms_stats.restore_table_stats(regclass, as_of_timestamp)
 */
\set VERBOSITY terse
-- No.10-3-1
SELECT dbms_stats.restore_table_stats('s0.st0', '2012-02-29 23:59:57');
-- No.10-3-2
SELECT dbms_stats.restore_table_stats('s0.st0', '2012-02-29 23:59:57.000002');
-- No.10-3-3
SELECT dbms_stats.restore_table_stats('s0.st0', '2012-01-01 00:00:00');
--#No.10-3-4 is skipped after lock tests
-- No.10-3-5
SELECT dbms_stats.restore_table_stats('s0.st0', '2012-02-29 23:59:57');
-- No.10-3-6
SELECT dbms_stats.restore_table_stats('st0', '2012-02-29 23:59:57');
\set VERBOSITY default
-- No.10-3-7
SELECT dbms_stats.restore_table_stats('s00.s0', '2012-02-29 23:59:57');
/*
 * Stab dbms_stats.restore_table_stats(regclass, as_of_timestamp)
 */
ALTER FUNCTION dbms_stats.restore_table_stats(regclass,
											  timestamp with time zone)
      RENAME TO truth_func_restore_table_stats;
CREATE OR REPLACE FUNCTION dbms_stats.restore_table_stats(
    relid regclass,
    as_of_timestamp timestamp with time zone)
RETURNS SETOF regclass AS
$$
BEGIN
    RAISE NOTICE 'arguments are %, %', $1, $2;
    RETURN QUERY
        SELECT $1;
END
$$
LANGUAGE plpgsql;

/*
 * No.10-4 dbms_stats.restore_table_stats(schemaname, tablename, as_of_timestamp)
 */
\set VERBOSITY terse
-- No.10-4-1
SELECT dbms_stats.restore_table_stats('s0', 'st0', '2012-02-29 23:59:57');
DROP FUNCTION dbms_stats.restore_table_stats(regclass,
											 timestamp with time zone);
ALTER FUNCTION dbms_stats.truth_func_restore_table_stats(regclass,
											  timestamp with time zone)
      RENAME TO restore_table_stats;

/*
 * No.10-5 dbms_stats.restore_column_stats(regclass, attname, as_of_timestamp)
 */
-- No.10-5-1
SELECT dbms_stats.restore_column_stats('s0.st0', 'id', '2012-02-29 23:59:57');
-- No.10-5-2
SELECT dbms_stats.restore_column_stats('s0.st0', 'id', '2012-02-29 23:59:57.000002');
-- No.10-5-3
SELECT dbms_stats.restore_column_stats('s0.st0', 'id', '2012-01-01 00:00:00');
--#No.10-5-4 is skipped after lock tests
-- No.10-5-5
SELECT dbms_stats.restore_column_stats('s0.st0', 'id', '2012-02-29 23:59:57');
-- No.10-5-6
SELECT dbms_stats.restore_column_stats('st0', 'id', '2012-02-29 23:59:57');
\set VERBOSITY default
-- No.10-5-7
SELECT dbms_stats.restore_column_stats('s00.s0', 'id', '2012-02-29 23:59:57');

/*
 * No.10-6 dbms_stats.restore_column_stats(
 *        schemaname, tablename, attname, as_of_timestamp)
 */
-- No.10-6-1
\set VERBOSITY terse
SELECT dbms_stats.restore_column_stats('s0', 'st0', 'id', '2012-02-29 23:59:57');
\set VERBOSITY default
/*
 * No.15-1 dbms_stats.purge_stats
 */
-- No.15-1-1
SELECT * FROM dbms_stats.backup_history;
BEGIN;
SELECT relation::regclass, mode
  FROM pg_locks
  WHERE
  	(relation::regclass::text LIKE 'dbms_stats.\_%\_locked'
     OR relation::regclass::text LIKE 'dbms_stats.backup_history'
     OR relation::regclass::text LIKE 'dbms_stats.%\_backup')
  AND
    mode <> 'ShareUpdateExclusiveLock'
  ORDER BY relation::regclass::text, mode;
SELECT id, unit, comment FROM dbms_stats.purge_stats(2);
SELECT relation::regclass, mode
  FROM pg_locks
  WHERE
  	(relation::regclass::text LIKE 'dbms_stats.\_%\_locked'
     OR relation::regclass::text LIKE 'dbms_stats.backup_history'
     OR relation::regclass::text LIKE 'dbms_stats.%\_backup')
  AND
    mode <> 'ShareUpdateExclusiveLock'
  ORDER BY relation::regclass::text, mode;
COMMIT;
SELECT * FROM dbms_stats.backup_history;
-- No.15-1-6
SELECT id, unit, comment FROM dbms_stats.purge_stats(NULL);
-- No.15-1-7
SELECT id, unit, comment FROM dbms_stats.purge_stats(-1);
-- No.15-1-8
SELECT id, unit, comment FROM dbms_stats.purge_stats(2, NULL);
-- No.15-1-4
SELECT * FROM dbms_stats.backup_history;
SELECT id, unit, comment FROM dbms_stats.purge_stats(3);
SELECT * FROM dbms_stats.backup_history;
-- No.15-1-5
SELECT * FROM dbms_stats.backup_history;
SELECT id, unit, comment FROM dbms_stats.purge_stats(6);
SELECT * FROM dbms_stats.backup_history;
-- No.15-1-2
SELECT * FROM dbms_stats.backup_history;
SELECT id, unit, comment FROM dbms_stats.purge_stats(8);
SELECT * FROM dbms_stats.backup_history;
-- No.15-1-3
SELECT * FROM dbms_stats.backup_history;
SELECT id, unit, comment FROM dbms_stats.purge_stats(8, true);
SELECT * FROM dbms_stats.backup_history;

/*
 * create backup statistics state A
 */
DELETE FROM dbms_stats.backup_history;

INSERT INTO dbms_stats.backup_history(id, time, unit)
    VALUES (1, '2012-02-29 23:59:56.999999', 'd');

SELECT setval('dbms_stats.backup_history_id_seq',1);
SELECT dbms_stats.backup();
UPDATE dbms_stats.backup_history
   SET time = '2012-02-29 23:59:57'
 WHERE id = 2;
SELECT dbms_stats.backup('s0.st0');
UPDATE dbms_stats.backup_history
   SET time = '2012-02-29 23:59:57.000001'
 WHERE id = 3;
SELECT dbms_stats.backup();
UPDATE dbms_stats.backup_history
   SET time = '2012-02-29 23:59:58'
 WHERE id = 4;
DELETE FROM dbms_stats.relation_stats_backup
 WHERE id = 4;
SELECT dbms_stats.backup('s0.st0', 'id');
UPDATE dbms_stats.backup_history
   SET time = '2012-03-01 00:00:00'
 WHERE id = 5;
SELECT dbms_stats.backup('s0.st0');
UPDATE dbms_stats.backup_history
   SET time = '2012-03-01 00:00:02'
 WHERE id = 6;
SELECT dbms_stats.backup('public.st0');
UPDATE dbms_stats.backup_history
   SET time = '2012-03-01 00:00:04'
 WHERE id = 7;
INSERT INTO dbms_stats.backup_history(time, unit)
    VALUES ('2012-03-01 00:00:06', 's');
SELECT dbms_stats.backup(8, c.oid, NULL)
  FROM pg_catalog.pg_class c,
       pg_catalog.pg_namespace n
 WHERE n.nspname = 's0'
   AND c.relnamespace = n.oid
   AND c.relkind IN ('r', 'i');

/*
 * restore test when only backup data does not exist 's0' schema
 */
DELETE FROM dbms_stats.column_stats_backup;
DELETE FROM dbms_stats.relation_stats_backup
 WHERE relname LIKE 's0.%';
SELECT count(*) FROM dbms_stats.relation_stats_backup;
SELECT count(*) FROM dbms_stats.column_stats_backup;
-- No.10-2-8
SELECT dbms_stats.restore_schema_stats('s0', '2012-03-01 00:00:04');

/*
 * restore test when there are only backup hisotory
 */
DELETE FROM dbms_stats.relation_stats_backup;
SELECT count(*) FROM dbms_stats.relation_stats_backup;
SELECT count(*) FROM dbms_stats.column_stats_backup;
-- No.10-1-5
SELECT dbms_stats.restore_database_stats('2012-02-29 23:59:58');
-- No.10-2-5
SELECT dbms_stats.restore_schema_stats('s0', '2012-02-29 23:59:58');
/*
 * restore when Backup does not exist
 */
DELETE FROM dbms_stats.backup_history;
SELECT count(*) FROM dbms_stats.backup_history;
SELECT count(*) FROM dbms_stats.relation_stats_backup;
SELECT count(*) FROM dbms_stats.column_stats_backup;

-- No.10-1-4
SELECT dbms_stats.restore_database_stats('2012-02-29 23:59:57');
-- No.10-2-4
SELECT dbms_stats.restore_schema_stats('s0', '2012-02-29 23:59:57');
-- No.10-3-4
\set VERBOSITY terse
SELECT dbms_stats.restore_table_stats('s0.st0', '2012-02-29 23:59:57');
-- No.10-5-4
SELECT dbms_stats.restore_column_stats('s0.st0', 'id', '2012-02-29 23:59:57');
\set VERBOSITY default
/*
 * Delete stab function dbms_stats.restore
 */
DROP FUNCTION dbms_stats.restore(int8, regclass, text);
ALTER FUNCTION dbms_stats.truth_func_restore(int8, regclass, text)
      RENAME TO restore;

/*
 * No.18-1 dbms_stats.clean_up_stats
 */
CREATE TABLE clean_test(id integer, num integer);
INSERT INTO clean_test SELECT i, i FROM generate_series(1,10) t(i);
ANALYZE clean_test;
-- No.18-1-1
-- No.18-1-5
SELECT dbms_stats.lock_table_stats('clean_test');
SELECT count(*) FROM dbms_stats.relation_stats_locked;
SELECT count(*) FROM dbms_stats.column_stats_locked;
SELECT dbms_stats.clean_up_stats() ORDER BY 1;
SELECT count(*) FROM dbms_stats.relation_stats_locked;
SELECT count(*) FROM dbms_stats.column_stats_locked;
-- No.18-1-2
-- No.18-1-7
DELETE FROM dbms_stats.relation_stats_locked;
SELECT count(*) FROM dbms_stats.relation_stats_locked;
SELECT count(*) FROM dbms_stats.column_stats_locked;
SELECT dbms_stats.clean_up_stats() ORDER BY 1;
SELECT count(*) FROM dbms_stats.relation_stats_locked;
SELECT count(*) FROM dbms_stats.column_stats_locked;
-- No.18-1-3
SELECT dbms_stats.lock_table_stats('clean_test');
DROP TABLE clean_test;
SELECT count(*) FROM dbms_stats.relation_stats_locked;
SELECT dbms_stats.clean_up_stats() ORDER BY 1;
SELECT count(*) FROM dbms_stats.relation_stats_locked;
-- No.18-1-4
DELETE FROM dbms_stats.relation_stats_locked;
SELECT count(*) FROM dbms_stats.relation_stats_locked;
SELECT dbms_stats.clean_up_stats() ORDER BY 1;
SELECT count(*) FROM dbms_stats.relation_stats_locked;
-- No.18-1-6
CREATE TABLE clean_test(id integer, num integer);
INSERT INTO clean_test SELECT i, i FROM generate_series(1,10) t(i);
ANALYZE clean_test;
SELECT dbms_stats.lock_table_stats('clean_test');
ALTER TABLE clean_test DROP COLUMN num;
ALTER TABLE clean_test ADD num integer;
UPDATE dbms_stats.column_stats_locked
   SET staattnum = 3
 WHERE starelid = 'clean_test'::regclass
   AND staattnum = 2;
UPDATE clean_test SET num = id;
SELECT count(*) FROM pg_statistic
 WHERE starelid = 'clean_test'::regclass;
SELECT count(*) FROM dbms_stats.column_stats_locked
 WHERE starelid = 'clean_test'::regclass;
SELECT dbms_stats.clean_up_stats() ORDER BY 1;
SELECT count(*) FROM dbms_stats.column_stats_locked
 WHERE starelid = 'clean_test'::regclass;
-- No.18-1-8
DELETE FROM dbms_stats.column_stats_locked
 WHERE starelid = 'clean_test'::regclass
   AND staattnum = 3;
SELECT count(*) FROM pg_statistic
 WHERE starelid = 'clean_test'::regclass;
SELECT count(*) FROM dbms_stats.column_stats_locked
 WHERE starelid = 'clean_test'::regclass;
SELECT dbms_stats.clean_up_stats() ORDER BY 1;
SELECT count(*) FROM dbms_stats.column_stats_locked
 WHERE starelid = 'clean_test'::regclass;
-- No.18-1-9
ANALYZE clean_test;
SELECT dbms_stats.lock_table_stats('clean_test');
ALTER TABLE clean_test DROP COLUMN num;
SELECT count(*) FROM dbms_stats.column_stats_locked
 WHERE starelid = 'clean_test'::regclass;
SELECT dbms_stats.clean_up_stats() ORDER BY 1;
SELECT count(*) FROM dbms_stats.column_stats_locked
 WHERE starelid = 'clean_test'::regclass;
-- No.18-1-10
DELETE FROM dbms_stats.column_stats_locked
 WHERE starelid = 'clean_test'::regclass
   AND staattnum = 3;
SELECT count(*) FROM dbms_stats.column_stats_locked
 WHERE starelid = 'clean_test'::regclass;
SELECT dbms_stats.clean_up_stats() ORDER BY 1;
SELECT count(*) FROM dbms_stats.column_stats_locked
 WHERE starelid = 'clean_test'::regclass;
DELETE FROM dbms_stats.relation_stats_locked;
DROP TABLE clean_test;

/*
 * No.19-1 dummy statistics view for general users privileges.
 */
SET SESSION AUTHORIZATION regular_user;
-- No.19-1-1
SELECT count(*) FROM dbms_stats.relation_stats_locked WHERE false;
-- No.19-1-2
SELECT count(*) FROM dbms_stats.column_stats_locked WHERE false;
-- No.19-1-3
SELECT count(*) FROM dbms_stats.stats WHERE false;
RESET SESSION AUTHORIZATION;

-- No.20 has been moved out to ut-xx.sql

/*
 * No.21 anyarray stuff
 */
CREATE TABLE st_ary (i int, f float, d timestamp without time zone);
INSERT INTO st_ary
 (SELECT a, random(), '2016-3-25 00:00:00'::date + (a || 'day')::interval
  FROM generate_series(0, 9999) a);
ANALYZE st_ary;
SELECT dbms_stats.lock('st_ary');

/* Identifying the base type of the target anyarray */
SELECT staattnum, dbms_stats.anyarray_basetype(stavalues1)
FROM dbms_stats.column_stats_locked
WHERE starelid = 'st_ary'::regclass
ORDER BY staattnum;

/* Generating subsidiary functions and casts */
SELECT staattnum,
	    dbms_stats.prepare_statstweak(
			dbms_stats.anyarray_basetype(stavalues1)::regtype)
FROM dbms_stats.column_stats_locked
WHERE starelid = 'st_ary'::regclass
ORDER BY staattnum;

/* Tweaking stats */
UPDATE dbms_stats.column_stats_locked
SET stavalues1 = '{1,2,3,4,5}'::int[]
WHERE starelid = 'st_ary'::regclass AND staattnum = 1;
UPDATE dbms_stats.column_stats_locked
SET stavalues1 = '{1.1,2.2,3.3,4.4,5.5}'::float8[]
WHERE starelid = 'st_ary'::regclass AND staattnum = 2;
UPDATE dbms_stats.column_stats_locked
SET stavalues1 =
  (SELECT ARRAY(SELECT '2016-1-1 0:0:0'::timestamp without time zone +
                (i || 'day')::interval
                FROM generate_series(0, 10) i))
WHERE starelid = 'st_ary'::regclass AND staattnum = 3;

SELECT staattnum, stavalues1 FROM dbms_stats.column_stats_locked
WHERE starelid = 'st_ary'::regclass
ORDER BY staattnum;

/* Dropping tweak stuff */
SELECT proname FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'dbms_stats' AND p.proname LIKE '\_%\_anyarray'
ORDER BY proname;

SELECT staattnum,
	    dbms_stats.drop_statstweak(
			dbms_stats.anyarray_basetype(stavalues1)::regtype)
FROM dbms_stats.column_stats_locked
WHERE starelid = 'st_ary'::regclass
ORDER BY staattnum;

SELECT proname FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'dbms_stats' AND p.proname LIKE '\_%\_anyarray'
ORDER BY proname;

/* Immediately unlock for safety */
SELECT dbms_stats.unlock('st_ary');
DROP TABLE st_ary;
