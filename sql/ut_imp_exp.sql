\getenv abs_srcdir PG_ABS_SRCDIR
\set dump_path :abs_srcdir '/export_stats.dmp'
\pset null '(null)'
CREATE TABLE s0.st3();
/*
 * No.16-1 export_plain_stats-15.sql.sample
 */
-- No.16-1-1
ANALYZE;
DELETE FROM dbms_stats.column_stats_locked;
DELETE FROM dbms_stats.relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
UPDATE dbms_stats.relation_stats_locked
   SET (relpages, reltuples, relallvisible, curpages) = (0,0,0,0);
UPDATE dbms_stats.column_stats_locked SET
    stanullfrac = -staattnum,
    stawidth = -staattnum,
    stadistinct = -staattnum,
    stakind1 = 2,
    stakind2 = 3,
    stakind3 = 4,
    stakind4 = 1,
    stakind5 = 5,
    staop1 = 22,
    staop2 = 23,
    staop3 = 24,
    staop4 = 21,
    staop5 = 25,
    stacoll1 = 32,
    stacoll2 = 33,
    stacoll3 = 34,
    stacoll4 = 31,
    stacoll5 = 35,
    stanumbers1 = ARRAY[-staattnum,22],
    stanumbers2 = ARRAY[-staattnum,23],
    stanumbers3 = ARRAY[-staattnum,24],
    stanumbers4 = ARRAY[-staattnum,21],
    stanumbers5 = ARRAY[-staattnum,25],
    stavalues1 = stavalues3,
    stavalues2 = stavalues2,
    stavalues3 = stavalues1,
    stavalues4 = stavalues4,
    stavalues5 = stavalues5;
\i doc/export_plain_stats-15.sql.sample
COPY dbms_stats.work FROM :'dump_path' (FORMAT 'binary');
SELECT * FROM work_v;
TRUNCATE dbms_stats.work;
-- No.16-1-2
\! sed '/ORDER/i\\ AND n2.nspname = '"\'s0\'" doc/export_plain_stats-15.sql.sample > doc/export_plain_stats-15.sql.sample_test
\i doc/export_plain_stats-15.sql.sample_test
COPY dbms_stats.work FROM :'dump_path' (FORMAT 'binary');
SELECT * FROM work_v;
TRUNCATE dbms_stats.work;
\! rm doc/export_plain_stats-15.sql.sample_test
-- No.16-1-3
\! sed '/ORDER/i\\ AND c.relname = '"\'st0\'" doc/export_plain_stats-15.sql.sample > doc/export_plain_stats-15.sql.sample_test
\i doc/export_plain_stats-15.sql.sample_test
COPY dbms_stats.work FROM :'dump_path' (FORMAT 'binary');
SELECT * FROM work_v;
TRUNCATE dbms_stats.work;
\! rm doc/export_plain_stats-15.sql.sample_test
-- No.16-1-3-1 Actual import test
select dbms_stats.import_database_stats(:'dump_path');
-- No.16-1-4
\! sed '/ORDER/i\\ AND c.relname = '"\'pg_toast_1262\'" doc/export_plain_stats-15.sql.sample > doc/export_plain_stats-15.sql.sample_test
\i doc/export_plain_stats-15.sql.sample_test
COPY dbms_stats.work FROM :'dump_path' (FORMAT 'binary');
SELECT * FROM work_v;
TRUNCATE dbms_stats.work;
\! rm doc/export_plain_stats-15.sql.sample_test
-- No.16-1-5
\! sed '/ORDER/i\\ AND c.relname = '"\'st0_idx\'" doc/export_plain_stats-15.sql.sample > doc/export_plain_stats-15.sql.sample_test
\i doc/export_plain_stats-15.sql.sample_test
COPY dbms_stats.work FROM :'dump_path' (FORMAT 'binary');
SELECT * FROM work_v;
TRUNCATE dbms_stats.work;
\! rm doc/export_plain_stats-15.sql.sample_test
-- No.16-1-6
\! sed '/ORDER/i\\ AND c.relname = '"\'ss0\'" doc/export_plain_stats-15.sql.sample > doc/export_plain_stats-15.sql.sample_test
\i doc/export_plain_stats-15.sql.sample_test
COPY dbms_stats.work FROM :'dump_path' (FORMAT 'binary');
SELECT * FROM work_v;
TRUNCATE dbms_stats.work;
\! rm doc/export_plain_stats-15.sql.sample_test
-- No.16-1-7
\! sed '/ORDER/i\\ AND c.relname = '"\'sc0\'" doc/export_plain_stats-15.sql.sample > doc/export_plain_stats-15.sql.sample_test
\i doc/export_plain_stats-15.sql.sample_test
COPY dbms_stats.work FROM :'dump_path' (FORMAT 'binary');
SELECT * FROM work_v;
TRUNCATE dbms_stats.work;
\! rm doc/export_plain_stats-15.sql.sample_test
-- No.16-1-8
\! sed '/ORDER/i\\ AND c.relname = '"\'sft0\'" doc/export_plain_stats-15.sql.sample > doc/export_plain_stats-15.sql.sample_test
\i doc/export_plain_stats-15.sql.sample_test
COPY dbms_stats.work FROM :'dump_path' (FORMAT 'binary');
SELECT * FROM work_v;
TRUNCATE dbms_stats.work;
\! rm doc/export_plain_stats-15.sql.sample_test
-- No.16-1-9
\! sed '/ORDER/i\\ AND c.relname = '"\'smv0\'" doc/export_plain_stats-15.sql.sample > doc/export_plain_stats-15.sql.sample_test
\i doc/export_plain_stats-15.sql.sample_test
COPY dbms_stats.work FROM :'dump_path' (FORMAT 'binary');
SELECT * FROM work_v;
TRUNCATE dbms_stats.work;
\! rm doc/export_plain_stats-15.sql.sample_test
-- No.16-1-10
\! sed '/ORDER/i\\ AND n2.nspname = '"\'s0\'"' AND a.attname = '\'id\' doc/export_plain_stats-15.sql.sample > doc/export_plain_stats-15.sql.sample_test
\i doc/export_plain_stats-15.sql.sample_test
COPY dbms_stats.work FROM :'dump_path' (FORMAT 'binary');
SELECT * FROM work_v;
TRUNCATE dbms_stats.work;
\! rm doc/export_plain_stats-15.sql.sample_test
-- No.16-1-11
\! sed '/ORDER/i\\ AND n2.nspname = '"\'s0\'"' AND a.attname IS NULL' doc/export_plain_stats-15.sql.sample > doc/export_plain_stats-15.sql.sample_test
\i doc/export_plain_stats-15.sql.sample_test
COPY dbms_stats.work FROM :'dump_path' (FORMAT 'binary');
SELECT * FROM work_v;
TRUNCATE dbms_stats.work;
\! rm doc/export_plain_stats-15.sql.sample_test
-- No.16-1-12
\! sed '/ORDER/i\\ AND n2.nspname = '"\'s1\'"' AND c.relname IS NULL' doc/export_plain_stats-15.sql.sample > doc/export_plain_stats-15.sql.sample_test
\i doc/export_plain_stats-15.sql.sample_test
COPY dbms_stats.work FROM :'dump_path' (FORMAT 'binary');
SELECT * FROM work_v;
TRUNCATE dbms_stats.work;
\! rm doc/export_plain_stats-15.sql.sample_test

/*
 * No.16-2 export_effective_stats-15.sql.sample
 */
-- No.16-2-1
VACUUM ANALYZE;
SELECT dbms_stats.lock_database_stats();
UPDATE dbms_stats.relation_stats_locked
   SET (relpages, reltuples, relallvisible, curpages) = (NULL, NULL, NULL, NULL);
UPDATE dbms_stats.column_stats_locked
   SET (stanullfrac, stawidth, stadistinct,
        stakind1, stakind2, stakind3, stakind4, stakind5,
        staop1, staop2, staop3, staop4, staop5,
        stacoll1, stacoll2, stacoll3, stacoll4, stacoll5,
        stanumbers1, stanumbers2, stanumbers3, stanumbers4, stanumbers5,
        stavalues1, stavalues2, stavalues3, stavalues4, stavalues5)
     = (NULL, NULL, NULL,
        NULL, NULL, NULL, NULL, NULL,
        NULL, NULL, NULL, NULL, NULL,
        NULL, NULL, NULL, NULL, NULL,
        NULL, NULL, NULL, NULL, NULL,
        NULL, NULL, NULL, NULL, NULL)
 WHERE starelid = 's0.st0'::regclass;
\i doc/export_effective_stats-15.sql.sample
COPY dbms_stats.work FROM :'dump_path' (FORMAT 'binary');
SELECT * FROM work_v;
TRUNCATE dbms_stats.work;
-- No.16-2-2
\! sed '/ORDER/i\\ WHERE n2.nspname = '"\'s0\'" doc/export_effective_stats-15.sql.sample > doc/export_effective_stats-15.sql.sample_test
\i doc/export_effective_stats-15.sql.sample_test
COPY dbms_stats.work FROM :'dump_path' (FORMAT 'binary');
SELECT * FROM work_v;
\! rm doc/export_effective_stats-15.sql.sample_test
TRUNCATE dbms_stats.work;
-- No.16-2-3
\! sed '/ORDER/i\\ WHERE cl.relname = '"\'st0\'" doc/export_effective_stats-15.sql.sample > doc/export_effective_stats-15.sql.sample_test
\i doc/export_effective_stats-15.sql.sample_test
COPY dbms_stats.work FROM :'dump_path' (FORMAT 'binary');
SELECT * FROM work_v;
\! rm doc/export_effective_stats-15.sql.sample_test
TRUNCATE dbms_stats.work;
-- No.16-2-4
\! sed '/ORDER/i\\ WHERE cl.relname = '"\'pg_toast_1262\'" doc/export_effective_stats-15.sql.sample > doc/export_effective_stats-15.sql.sample_test
\i doc/export_effective_stats-15.sql.sample_test
COPY dbms_stats.work FROM :'dump_path' (FORMAT 'binary');
SELECT * FROM work_v;
\! rm doc/export_effective_stats-15.sql.sample_test
TRUNCATE dbms_stats.work;
-- No.16-2-5
\! sed '/ORDER/i\\ WHERE cl.relname = '"\'st0_idx\'" doc/export_effective_stats-15.sql.sample > doc/export_effective_stats-15.sql.sample_test
\i doc/export_effective_stats-15.sql.sample_test
COPY dbms_stats.work FROM :'dump_path' (FORMAT 'binary');
SELECT * FROM work_v;
\! rm doc/export_effective_stats-15.sql.sample_test
TRUNCATE dbms_stats.work;
-- No.16-2-6
\! sed '/ORDER/i\\ WHERE cl.relname = '"\'ss0\'" doc/export_effective_stats-15.sql.sample > doc/export_effective_stats-15.sql.sample_test
\i doc/export_effective_stats-15.sql.sample_test
COPY dbms_stats.work FROM :'dump_path' (FORMAT 'binary');
SELECT * FROM work_v;
\! rm doc/export_effective_stats-15.sql.sample_test
TRUNCATE dbms_stats.work;
-- No.16-2-7
\! sed '/ORDER/i\\ WHERE cl.relname = '"\'sc0\'" doc/export_effective_stats-15.sql.sample > doc/export_effective_stats-15.sql.sample_test
\i doc/export_effective_stats-15.sql.sample_test
COPY dbms_stats.work FROM :'dump_path' (FORMAT 'binary');
SELECT * FROM work_v;
\! rm doc/export_effective_stats-15.sql.sample_test
TRUNCATE dbms_stats.work;
-- No.16-2-8
\! sed '/ORDER/i\\ WHERE cl.relname = '"\'sft0\'" doc/export_effective_stats-15.sql.sample > doc/export_effective_stats-15.sql.sample_test
\i doc/export_effective_stats-15.sql.sample_test
COPY dbms_stats.work FROM :'dump_path' (FORMAT 'binary');
SELECT * FROM work_v;
\! rm doc/export_effective_stats-15.sql.sample_test
TRUNCATE dbms_stats.work;
-- No.16-2-9
\! sed '/ORDER/i\\ WHERE cl.relname = '"\'smv0\'" doc/export_effective_stats-15.sql.sample > doc/export_effective_stats-15.sql.sample_test
\i doc/export_effective_stats-15.sql.sample_test
COPY dbms_stats.work FROM :'dump_path' (FORMAT 'binary');
SELECT * FROM work_v;
\! rm doc/export_effective_stats-15.sql.sample_test
TRUNCATE dbms_stats.work;
-- No.16-2-10
\! sed '/ORDER/i\\ WHERE n2.nspname = '"\'s0\'"' AND a.attname = '"\'id\'" doc/export_effective_stats-15.sql.sample > doc/export_effective_stats-15.sql.sample_test
\i doc/export_effective_stats-15.sql.sample_test
COPY dbms_stats.work FROM :'dump_path' (FORMAT 'binary');
SELECT * FROM work_v;
\! rm doc/export_effective_stats-15.sql.sample_test
TRUNCATE dbms_stats.work;
-- No.16-2-11
\! sed '/ORDER/i\\ WHERE n2.nspname = '"\'s0\'"' AND a.attname IS NULL' doc/export_effective_stats-15.sql.sample > doc/export_effective_stats-15.sql.sample_test
\i doc/export_effective_stats-15.sql.sample_test
COPY dbms_stats.work FROM :'dump_path' (FORMAT 'binary');
SELECT * FROM work_v;
\! rm doc/export_effective_stats-15.sql.sample_test
TRUNCATE dbms_stats.work;
-- No.16-2-12
\! sed '/ORDER/i\\ WHERE n2.nspname = '"\'s0\'"' AND cl.relname IS NULL' doc/export_effective_stats-15.sql.sample > doc/export_effective_stats-15.sql.sample_test
\i doc/export_effective_stats-15.sql.sample_test
COPY dbms_stats.work FROM :'dump_path' (FORMAT 'binary');
SELECT * FROM work_v;
\! rm doc/export_effective_stats-15.sql.sample_test
TRUNCATE dbms_stats.work;

/*
 * Stab function dbms_stats.import
 */
ALTER FUNCTION dbms_stats.import(
    nspname text,
    relid regclass,
    attname text,
    src text
) RENAME TO truth_import;
CREATE FUNCTION dbms_stats.import(
    nspname text,
    relid regclass,
    attname text,
    src text
) RETURNS void AS
$$
BEGIN
    RAISE NOTICE 'arguments are "%", "%", "%", "%"', $1, $2, $3, $4;
    RETURN;
END
$$
LANGUAGE plpgsql;
/*
 * No.17-1 dbms_stats.import_database_stats(src)
 */
-- No.17-1-1
SELECT dbms_stats.import_database_stats('export_stats.dmp');

/*
 * No.17-2 dbms_stats.import_schema_stats(schemaname, src)
 */
-- No.17-2-1
SELECT dbms_stats.import_schema_stats('s0', 'export_stats.dmp');

/*
 * No.17-3 dbms_stats.import_table_stats(relid, src)
 */
-- No.17-3-1
SELECT dbms_stats.import_table_stats('s0.st0', 'export_stats.dmp');

/*
 * No.17-4 dbms_stats.import_table_stats(schemaname, tablename, src)
 */
-- No.17-4-1
SELECT dbms_stats.import_table_stats('s0', 'st0', 'export_stats.dmp');

/*
 * No.17-5 dbms_stats.import_column_stats (relid, attname, src)
 */
-- No.17-5-1
SELECT dbms_stats.import_column_stats('s0.st0', 'id', 'export_stats.dmp');

/*
 * No.17-6 dbms_stats.import_column_stats (schemaname, tablename, attname, src)
 */
-- No.17-6-1
SELECT dbms_stats.import_column_stats('s0', 'st0', 'id', 'export_stats.dmp');

/*
 * Delete stab function dbms_stats.import
 */
DROP FUNCTION dbms_stats.import(
    nspname text,
    relid regclass,
    attname text,
    src text
);
ALTER FUNCTION dbms_stats.truth_import(
    nspname text,
    relid regclass,
    attname text,
    src text
) RENAME TO import;
