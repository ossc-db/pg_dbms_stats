\pset null '(null)'
/*
 * No.2-1 table definitions.
 */
-- No.2-1-1
\d dbms_stats.backup_history
-- No.2-1-2
\d dbms_stats.column_stats_backup
-- No.2-1-3
\d dbms_stats._column_stats_locked
-- No.2-1-4
\d dbms_stats.relation_stats_backup
-- No.2-1-5
\d dbms_stats._relation_stats_locked

/*
 * No.2-2 view definitions.
 */
-- No.2-2-1
\dS+ dbms_stats.column_stats_effective
-- No.2-2-2
\dS+ dbms_stats.relation_stats_effective
-- No.2-2-3
\dS+ dbms_stats.stats
-- No.2-2-4
\dS+ dbms_stats.column_stats_locked
-- No.2-2-5
\dS+ dbms_stats.relation_stats_locked

/*
 * No.2-4 dbms_stats.anyarray
 */
-- No.2-4-1
SELECT n.nspname, t.typname, t.typlen, t.typbyval, t.typtype,
       t.typcategory, t.typispreferred, t.typisdefined, t.typdelim,
       t.typrelid, t.typelem, t.typinput, t.typoutput, t.typreceive,
       t.typsend, t.typmodin, t.typmodout, t.typanalyze, t.typalign,
       t.typstorage, t.typnotnull, t.typbasetype, t.typtypmod, t.typndims,
       t.typcollation, t.typdefaultbin, t.typdefault, t.typacl
  FROM pg_type t, pg_namespace n
 WHERE t.typnamespace = n.oid
   AND n.nspname = 'dbms_stats'
   AND t.typname = 'anyarray';

/*
 * No.5-1 dbms_stats.merge
 */
UPDATE pg_statistic SET
    stanullfrac = staattnum,
    stawidth = staattnum,
    stadistinct = staattnum,
    stakind1 = 4,
    stakind2 = 1,
    stakind3 = 2,
    stakind4 = 3,
    stakind5 = 5,
    staop1 = 14,
    staop2 = 11,
    staop3 = 12,
    staop4 = 13,
    staop5 = 15,
    stanumbers1 = ARRAY[staattnum,4],
    stanumbers2 = ARRAY[staattnum,1],
    stanumbers3 = ARRAY[staattnum,2],
    stanumbers4 = ARRAY[staattnum,3],
    stanumbers5 = ARRAY[staattnum,5],
    stavalues2 = array_cat(stavalues1,stavalues1),
    stavalues3 = array_cat(array_cat(stavalues1,stavalues1),stavalues1),
    stavalues4 = array_cat(array_cat(array_cat(stavalues1,stavalues1),stavalues1),stavalues1)
   ,stavalues5 = array_cat(array_cat(array_cat(array_cat(stavalues1,stavalues1),stavalues1),stavalues1),stavalues1)
 WHERE starelid = 'st0'::regclass;
SELECT dbms_stats.lock_table_stats('st0');
UPDATE dbms_stats._column_stats_locked SET
    stainherit = 't',
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
    stanumbers1 = ARRAY[-staattnum,22],
    stanumbers2 = ARRAY[-staattnum,23],
    stanumbers3 = ARRAY[-staattnum,24],
    stanumbers4 = ARRAY[-staattnum,21],
    stanumbers5 = ARRAY[-staattnum,25],
    stavalues1 = stavalues3,
    stavalues2 = stavalues2,
    stavalues3 = stavalues1,
    stavalues4 = stavalues4
   ,stavalues5 = stavalues5
;

/*
 * Driver function dbms_stats.merge1
 */
CREATE FUNCTION dbms_stats.merge1(
    lhs dbms_stats._column_stats_locked,
    rhs pg_catalog.pg_statistic
) RETURNS integer AS
'$libdir/pg_dbms_stats', 'dbms_stats_merge'
LANGUAGE C STABLE;

SELECT * FROM columns_locked_v
 WHERE starelid = 'st0'::regclass;
SELECT * FROM plain_columns_statistic_v
 WHERE starelid = 'st0'::regclass;

SET client_min_messages TO LOG;

-- No.5-1-1
SELECT (m.merge).starelid::regclass,
       (m.merge).staattnum,
       (m.merge).stainherit,
       (m.merge).stanullfrac,
       (m.merge).stawidth,
       (m.merge).stadistinct,
       (m.merge).stakind1,
       (m.merge).stakind2,
       (m.merge).stakind3,
       (m.merge).stakind4,
       (m.merge).stakind5,
       (m.merge).staop1,
       (m.merge).staop2,
       (m.merge).staop3,
       (m.merge).staop4,
       (m.merge).staop5,
       (m.merge).stanumbers1,
       (m.merge).stanumbers2,
       (m.merge).stanumbers3,
       (m.merge).stanumbers4,
       (m.merge).stanumbers5,
       (m.merge).stavalues1,
       (m.merge).stavalues2,
       (m.merge).stavalues3,
       (m.merge).stavalues4
      ,(m.merge).stavalues5
 FROM (SELECT dbms_stats.merge(NULL, s)
         FROM pg_statistic s
        WHERE starelid = 'st0'::regclass
          AND staattnum = '1'::int2) m;

-- No.5-1-2
SELECT (m.merge).starelid::regclass,
       (m.merge).staattnum,
       (m.merge).stainherit,
       (m.merge).stanullfrac,
       (m.merge).stawidth,
       (m.merge).stadistinct,
       (m.merge).stakind1,
       (m.merge).stakind2,
       (m.merge).stakind3,
       (m.merge).stakind4,
       (m.merge).stakind5,
       (m.merge).staop1,
       (m.merge).staop2,
       (m.merge).staop3,
       (m.merge).staop4,
       (m.merge).staop5,
       (m.merge).stanumbers1,
       (m.merge).stanumbers2,
       (m.merge).stanumbers3,
       (m.merge).stanumbers4,
       (m.merge).stanumbers5,
       (m.merge).stavalues1,
       (m.merge).stavalues2,
       (m.merge).stavalues3,
       (m.merge).stavalues4
      ,(m.merge).stavalues5
 FROM (SELECT dbms_stats.merge(v, NULL)
         FROM dbms_stats._column_stats_locked v
        WHERE starelid = 'st0'::regclass
          AND staattnum = '2'::int2) m;

-- No.5-1-3
SELECT dbms_stats.merge(NULL, NULL);

-- No.5-1-4
SELECT (m.merge).starelid::regclass,
       (m.merge).staattnum,
       (m.merge).stainherit,
       (m.merge).stanullfrac,
       (m.merge).stawidth,
       (m.merge).stadistinct,
       (m.merge).stakind1,
       (m.merge).stakind2,
       (m.merge).stakind3,
       (m.merge).stakind4,
       (m.merge).stakind5,
       (m.merge).staop1,
       (m.merge).staop2,
       (m.merge).staop3,
       (m.merge).staop4,
       (m.merge).staop5,
       (m.merge).stanumbers1,
       (m.merge).stanumbers2,
       (m.merge).stanumbers3,
       (m.merge).stanumbers4,
       (m.merge).stanumbers5,
       (m.merge).stavalues1,
       (m.merge).stavalues2,
       (m.merge).stavalues3,
       (m.merge).stavalues4
      ,(m.merge).stavalues5
 FROM (SELECT dbms_stats.merge(v, s)
         FROM dbms_stats._column_stats_locked v,
              pg_statistic s
        WHERE v.starelid = 'st0'::regclass
          AND v.staattnum = '2'::int2
          AND s.starelid = 'st0'::regclass
          AND s.staattnum = '1'::int2) m;

-- No.5-1-5
SELECT (m.merge).starelid::regclass,
       (m.merge).staattnum,
       (m.merge).stainherit,
       (m.merge).stanullfrac,
       (m.merge).stawidth,
       (m.merge).stadistinct,
       (m.merge).stakind1,
       (m.merge).stakind2,
       (m.merge).stakind3,
       (m.merge).stakind4,
       (m.merge).stakind5,
       (m.merge).staop1,
       (m.merge).staop2,
       (m.merge).staop3,
       (m.merge).staop4,
       (m.merge).staop5,
       (m.merge).stanumbers1,
       (m.merge).stanumbers2,
       (m.merge).stanumbers3,
       (m.merge).stanumbers4,
       (m.merge).stanumbers5,
       (m.merge).stavalues1,
       (m.merge).stavalues2,
       (m.merge).stavalues3,
       (m.merge).stavalues4
      ,(m.merge).stavalues5
 FROM (SELECT dbms_stats.merge(v, s)
         FROM dbms_stats._column_stats_locked v,
              pg_statistic s
        WHERE v.starelid = 'st0'::regclass
          AND v.staattnum = '2'::int2
          AND s.starelid = 'st0'::regclass
          AND s.staattnum = '1'::int2) m;

-- No.5-1-6
SELECT dbms_stats.merge1(v, s)
  FROM dbms_stats._column_stats_locked v,
       pg_statistic s
 WHERE v.starelid = 'st0'::regclass
   AND v.staattnum = '2'::int2
   AND s.starelid = 'st0'::regclass
   AND s.staattnum = '1'::int2;

-- No.5-1-7
SELECT dbms_stats.merge(NULL, (
       s.starelid::regclass, s.staattnum, s.stainherit,
       s.stanullfrac, s.stawidth, s.stadistinct,
       s.stakind1, s.stakind2, s.stakind3, s.stakind4,
       s.stakind5,
       s.staop1, s.staop2, s.staop3,
       s.staop4,
       NULL, s.stanumbers1, s.stanumbers2, s.stanumbers3, s.stanumbers4,
       s.stanumbers5,
       s.stavalues1, s.stavalues2, s.stavalues3, s.stavalues4
      ,s.stavalues5
       ))
  FROM pg_statistic s
 WHERE s.starelid = 'st0'::regclass
   AND s.staattnum = '1'::int2;

-- No.5-1-8
SELECT (m.merge).starelid::regclass,
       (m.merge).staattnum,
       (m.merge).stainherit,
       (m.merge).stanullfrac,
       (m.merge).stawidth,
       (m.merge).stadistinct,
       (m.merge).stakind1,
       (m.merge).stakind2,
       (m.merge).stakind3,
       (m.merge).stakind4,
       (m.merge).stakind5,
       (m.merge).staop1,
       (m.merge).staop2,
       (m.merge).staop3,
       (m.merge).staop4,
       (m.merge).staop5,
       (m.merge).stanumbers1,
       (m.merge).stanumbers2,
       (m.merge).stanumbers3,
       (m.merge).stanumbers4,
       (m.merge).stanumbers5,
       (m.merge).stavalues1,
       (m.merge).stavalues2,
       (m.merge).stavalues3,
       (m.merge).stavalues4
      ,(m.merge).stavalues5
 FROM (SELECT dbms_stats.merge(NULL, (
              s.starelid::regclass, s.staattnum, s.stainherit,
              s.stanullfrac, s.stawidth, s.stadistinct,
              s.stakind1, s.stakind2, s.stakind3, s.stakind4,
              s.stakind5,
              s.staop1, s.staop2, s.staop3, s.staop4,
              s.staop5,
              NULL, s.stanumbers2, s.stanumbers3, s.stanumbers4,
              s.stanumbers5,
              s.stavalues1, s.stavalues2, s.stavalues3, s.stavalues4
             ,s.stavalues5
              ))
         FROM pg_statistic s
        WHERE s.starelid = 'st0'::regclass
          AND s.staattnum = '1'::int2) m;

-- No.5-1-9
SELECT dbms_stats.merge((
       v.starelid::regclass, v.staattnum, v.stainherit,
       v.stanullfrac, v.stawidth, v.stadistinct,
       v.stakind1, v.stakind2, v.stakind3, v.stakind4,
       v.stakind5,
       v.staop1, v.staop2, v.staop3,
       v.staop4,
       NULL, v.stanumbers1, v.stanumbers2, v.stanumbers3, v.stanumbers4,
       v.stanumbers5,
       v.stavalues1, v.stavalues2, v.stavalues3, v.stavalues4
      ,v.stavalues5
       ), NULL)
  FROM dbms_stats._column_stats_locked v
 WHERE v.starelid = 'st0'::regclass
   AND v.staattnum = '2'::int2;

-- No.5-1-10
SELECT (m.merge).starelid::regclass,
       (m.merge).staattnum,
       (m.merge).stainherit,
       (m.merge).stanullfrac,
       (m.merge).stawidth,
       (m.merge).stadistinct,
       (m.merge).stakind1,
       (m.merge).stakind2,
       (m.merge).stakind3,
       (m.merge).stakind4,
       (m.merge).stakind5,
       (m.merge).staop1,
       (m.merge).staop2,
       (m.merge).staop3,
       (m.merge).staop4,
       (m.merge).staop5,
       (m.merge).stanumbers1,
       (m.merge).stanumbers2,
       (m.merge).stanumbers3,
       (m.merge).stanumbers4,
       (m.merge).stanumbers5,
       (m.merge).stavalues1,
       (m.merge).stavalues2,
       (m.merge).stavalues3,
       (m.merge).stavalues4
      ,(m.merge).stavalues5
 FROM (SELECT dbms_stats.merge((
              v.starelid::regclass, v.staattnum, v.stainherit,
              v.stanullfrac, v.stawidth, v.stadistinct,
              v.stakind1, v.stakind2, v.stakind3, v.stakind4,
              v.stakind5,
              v.staop1, v.staop2, v.staop3, v.staop4,
              v.staop5,
              NULL, v.stanumbers2, v.stanumbers3, v.stanumbers4,
              v.stanumbers5,
              v.stavalues1, v.stavalues2, v.stavalues3, v.stavalues4
             ,v.stavalues5
              ), NULL)
         FROM dbms_stats._column_stats_locked v
        WHERE v.starelid = 'st0'::regclass
          AND v.staattnum = '2'::int2) m;

-- No.5-1-11
SELECT dbms_stats.merge((
       v.starelid::regclass, v.staattnum, v.stainherit,
       v.stanullfrac, v.stawidth, v.stadistinct,
       v.stakind1, v.stakind2, v.stakind3, v.stakind4,
       v.stakind5,
       v.staop1, v.staop2, v.staop3,
       v.staop4,
       NULL, v.stanumbers1, v.stanumbers2, v.stanumbers3, v.stanumbers4,
       v.stanumbers5,
       v.stavalues1, v.stavalues2, v.stavalues3, v.stavalues4
      ,v.stavalues5
       ), (
       s.starelid::regclass, s.staattnum, s.stainherit,
       s.stanullfrac, s.stawidth, s.stadistinct,
       s.stakind1, s.stakind2, s.stakind3, s.stakind4,
       s.stakind5,
       s.staop1, s.staop2, s.staop3,
       s.staop4,
       NULL, s.stanumbers1, s.stanumbers2, s.stanumbers3, s.stanumbers4,
       s.stanumbers5,
       s.stavalues1, s.stavalues2, s.stavalues3, s.stavalues4
      ,s.stavalues5
       ))
  FROM dbms_stats._column_stats_locked v,
       pg_statistic s
 WHERE v.starelid = 'st0'::regclass
   AND v.staattnum = '2'::int2
   AND s.starelid = 'st0'::regclass
   AND s.staattnum = '1'::int2;

-- No.5-1-12
SELECT (m.merge).starelid::regclass,
       (m.merge).staattnum,
       (m.merge).stainherit,
       (m.merge).stanullfrac,
       (m.merge).stawidth,
       (m.merge).stadistinct,
       (m.merge).stakind1,
       (m.merge).stakind2,
       (m.merge).stakind3,
       (m.merge).stakind4,
       (m.merge).stakind5,
       (m.merge).staop1,
       (m.merge).staop2,
       (m.merge).staop3,
       (m.merge).staop4,
       (m.merge).staop5,
       (m.merge).stanumbers1,
       (m.merge).stanumbers2,
       (m.merge).stanumbers3,
       (m.merge).stanumbers4,
       (m.merge).stanumbers5,
       (m.merge).stavalues1,
       (m.merge).stavalues2,
       (m.merge).stavalues3,
       (m.merge).stavalues4
      ,(m.merge).stavalues5
 FROM (SELECT dbms_stats.merge((
              v.starelid::regclass, v.staattnum, v.stainherit,
              v.stanullfrac, v.stawidth, v.stadistinct,
              v.stakind1, v.stakind2, v.stakind3, v.stakind4,
              v.stakind5,
              v.staop1, v.staop2, v.staop3, v.staop4,
              v.staop5,
              NULL, v.stanumbers2, v.stanumbers3, v.stanumbers4,
              v.stanumbers5,
              v.stavalues1, v.stavalues2, v.stavalues3, v.stavalues4
             ,v.stavalues5
              ), (
              s.starelid::regclass, s.staattnum, s.stainherit,
              s.stanullfrac, s.stawidth, s.stadistinct,
              s.stakind1, s.stakind2, s.stakind3, s.stakind4,
              s.stakind5,
              s.staop1, s.staop2, s.staop3, s.staop4,
              s.staop5,
              NULL, s.stanumbers2, s.stanumbers3, s.stanumbers4,
              s.stanumbers5,
              s.stavalues1, s.stavalues2, s.stavalues3, s.stavalues4
             ,s.stavalues5
              ))
         FROM dbms_stats._column_stats_locked v,
              pg_statistic s
        WHERE v.starelid = 'st0'::regclass
          AND v.staattnum = '2'::int2
          AND s.starelid = 'st0'::regclass
          AND s.staattnum = '1'::int2) m;

-- No.5-1-13
SELECT (m.merge).starelid::regclass,
       (m.merge).staattnum,
       (m.merge).stainherit,
       (m.merge).stanullfrac,
       (m.merge).stawidth,
       (m.merge).stadistinct,
       (m.merge).stakind1,
       (m.merge).stakind2,
       (m.merge).stakind3,
       (m.merge).stakind4,
       (m.merge).stakind5,
       (m.merge).staop1,
       (m.merge).staop2,
       (m.merge).staop3,
       (m.merge).staop4,
       (m.merge).staop5,
       (m.merge).stanumbers1,
       (m.merge).stanumbers2,
       (m.merge).stanumbers3,
       (m.merge).stanumbers4,
       (m.merge).stanumbers5,
       (m.merge).stavalues1,
       (m.merge).stavalues2,
       (m.merge).stavalues3,
       (m.merge).stavalues4
      ,(m.merge).stavalues5
 FROM (SELECT dbms_stats.merge((
             NULL, NULL, NULL,
             NULL, NULL, NULL,
             NULL, NULL, NULL, NULL,
             NULL, NULL, NULL, NULL,
             NULL, NULL, NULL, NULL,
             NULL, NULL, NULL, NULL
            ,NULL, NULL, NULL, NULL
             ), s)
         FROM pg_statistic s
        WHERE s.starelid = 'st0'::regclass
          AND s.staattnum = '1'::int2) m;

-- No.5-1-14
SELECT (m.merge).starelid::regclass,
       (m.merge).staattnum,
       (m.merge).stainherit,
       (m.merge).stanullfrac,
       (m.merge).stawidth,
       (m.merge).stadistinct,
       (m.merge).stakind1,
       (m.merge).stakind2,
       (m.merge).stakind3,
       (m.merge).stakind4,
       (m.merge).stakind5,
       (m.merge).staop1,
       (m.merge).staop2,
       (m.merge).staop3,
       (m.merge).staop4,
       (m.merge).staop5,
       (m.merge).stanumbers1,
       (m.merge).stanumbers2,
       (m.merge).stanumbers3,
       (m.merge).stanumbers4,
       (m.merge).stanumbers5,
       (m.merge).stavalues1,
       (m.merge).stavalues2,
       (m.merge).stavalues3,
       (m.merge).stavalues4
      ,(m.merge).stavalues5
 FROM (SELECT dbms_stats.merge(v, (
             NULL, NULL, NULL,
             NULL, NULL, NULL,
             NULL, NULL, NULL, NULL,
             NULL, NULL, NULL, NULL,
             NULL, NULL, NULL, NULL,
             NULL, NULL, NULL, NULL,
             NULL, NULL, NULL, NULL))
         FROM dbms_stats._column_stats_locked v
        WHERE v.starelid = 'st0'::regclass
          AND v.staattnum = '2'::int2) m;

-- No.5-1-15
SELECT (m.merge).starelid::regclass,
       (m.merge).staattnum,
       (m.merge).stainherit,
       (m.merge).stanullfrac,
       (m.merge).stawidth,
       (m.merge).stadistinct,
       (m.merge).stakind1,
       (m.merge).stakind2,
       (m.merge).stakind3,
       (m.merge).stakind4,
       (m.merge).stakind5,
       (m.merge).staop1,
       (m.merge).staop2,
       (m.merge).staop3,
       (m.merge).staop4,
       (m.merge).staop5,
       (m.merge).stanumbers1,
       (m.merge).stanumbers2,
       (m.merge).stanumbers3,
       (m.merge).stanumbers4,
       (m.merge).stanumbers5,
       (m.merge).stavalues1,
       (m.merge).stavalues2,
       (m.merge).stavalues3,
       (m.merge).stavalues4
      ,(m.merge).stavalues5
 FROM (SELECT dbms_stats.merge(v, s)
         FROM dbms_stats._column_stats_locked v,
              pg_statistic s
        WHERE v.starelid = 'st0'::regclass
          AND v.staattnum = '2'::int2
          AND s.starelid = 'st0'::regclass
          AND s.staattnum = '1'::int2) m;

-- No.5-1-16
SELECT dbms_stats.merge((
       v.starelid::regclass, v.staattnum, v.stainherit,
       v.stanullfrac, v.stawidth, v.stadistinct,
       NULL, NULL, NULL, NULL,
       NULL, NULL, NULL, NULL,
       NULL, NULL, NULL, NULL,
       NULL, NULL, NULL, NULL
      ,NULL, NULL, NULL, NULL
       ), (
       s.starelid::regclass, s.staattnum, s.stainherit,
       s.stanullfrac, s.stawidth, s.stadistinct,
       NULL, NULL, NULL, NULL,
       NULL, NULL, NULL, NULL,
       NULL, NULL, NULL, NULL,
       NULL, NULL, NULL, NULL,
       NULL, NULL, NULL, NULL))
  FROM dbms_stats._column_stats_locked v,
       pg_statistic s
 WHERE v.starelid = 'st0'::regclass
   AND v.staattnum = '2'::int2
   AND s.starelid = 'st0'::regclass
   AND s.staattnum = '1'::int2;

-- No.5-1-17
SELECT (m.merge).starelid::regclass,
       (m.merge).staattnum,
       (m.merge).stainherit,
       (m.merge).stanullfrac,
       (m.merge).stawidth,
       (m.merge).stadistinct,
       (m.merge).stakind1,
       (m.merge).stakind2,
       (m.merge).stakind3,
       (m.merge).stakind4,
       (m.merge).stakind5,
       (m.merge).staop1,
       (m.merge).staop2,
       (m.merge).staop3,
       (m.merge).staop4,
       (m.merge).staop5,
       (m.merge).stanumbers1,
       (m.merge).stanumbers2,
       (m.merge).stanumbers3,
       (m.merge).stanumbers4,
       (m.merge).stanumbers5,
       (m.merge).stavalues1,
       (m.merge).stavalues2,
       (m.merge).stavalues3,
       (m.merge).stavalues4
      ,(m.merge).stavalues5
 FROM (SELECT dbms_stats.merge((
              v.starelid::regclass, v.staattnum, v.stainherit,
              v.stanullfrac, v.stawidth, v.stadistinct,
              v.stakind1, v.stakind2, v.stakind3, v.stakind4,
              v.stakind5,
              v.staop1, v.staop2, v.staop3,
              v.staop4,
              NULL, v.stanumbers1, v.stanumbers2, v.stanumbers3, v.stanumbers4,
              v.stanumbers5,
              v.stavalues1, v.stavalues2, v.stavalues3, v.stavalues4
             ,v.stavalues5
              ), (
              s.starelid::regclass, s.staattnum, s.stainherit,
              s.stanullfrac, s.stawidth, s.stadistinct,
              s.stakind1, s.stakind2, s.stakind3, s.stakind4,
              s.stakind5,
              s.staop1, s.staop2, s.staop3, s.staop4,
              s.staop5,
              s.stanumbers1, s.stanumbers2, s.stanumbers3, s.stanumbers4,
              s.stanumbers5,
              s.stavalues1, s.stavalues2, s.stavalues3, s.stavalues4
             ,s.stavalues5
              ))
         FROM dbms_stats._column_stats_locked v,
              pg_statistic s
        WHERE v.starelid = 'st0'::regclass
          AND v.staattnum = '1'::int2
          AND s.starelid = 'st0'::regclass
          AND s.staattnum = '1'::int2) m;

-- No.5-1-18
SELECT dbms_stats.merge((
       v.starelid::regclass, v.staattnum, v.stainherit,
       v.stanullfrac, v.stawidth, v.stadistinct,
       v.stakind1, v.stakind2, v.stakind3, v.stakind4,
       v.stakind5,
       v.staop1, v.staop2, v.staop3,
       v.staop4,
       NULL, v.stanumbers1, v.stanumbers2, v.stanumbers3, v.stanumbers4,
       v.stanumbers5,
       v.stavalues1, v.stavalues2, v.stavalues3, v.stavalues4
      ,v.stavalues5
       ), (
       s.starelid::regclass, s.staattnum, s.stainherit,
       s.stanullfrac, s.stawidth, s.stadistinct,
       s.stakind1, s.stakind2, s.stakind3, s.stakind4,
       s.stakind5,
       s.staop1, s.staop2, s.staop3,
       s.staop4,
       NULL, s.stanumbers1, s.stanumbers2, s.stanumbers3, s.stanumbers4,
       s.stanumbers5,
       s.stavalues1, s.stavalues2, s.stavalues3, s.stavalues4
      ,s.stavalues5
       ))
  FROM dbms_stats._column_stats_locked v,
       pg_statistic s
 WHERE v.starelid = 'st0'::regclass
   AND v.staattnum = '1'::int2
   AND s.starelid = 'st0'::regclass
   AND s.staattnum = '1'::int2;

-- No.5-1-19
SELECT (m.merge).starelid::regclass,
       (m.merge).staattnum,
       (m.merge).stainherit,
       (m.merge).stanullfrac,
       (m.merge).stawidth,
       (m.merge).stadistinct,
       (m.merge).stakind1,
       (m.merge).stakind2,
       (m.merge).stakind3,
       (m.merge).stakind4,
       (m.merge).stakind5,
       (m.merge).staop1,
       (m.merge).staop2,
       (m.merge).staop3,
       (m.merge).staop4,
       (m.merge).staop5,
       (m.merge).stanumbers1,
       (m.merge).stanumbers2,
       (m.merge).stanumbers3,
       (m.merge).stanumbers4,
       (m.merge).stanumbers5,
       (m.merge).stavalues1,
       (m.merge).stavalues2,
       (m.merge).stavalues3,
       (m.merge).stavalues4
      ,(m.merge).stavalues5
 FROM (SELECT dbms_stats.merge((
              v.starelid::regclass, v.staattnum, v.stainherit,
              v.stanullfrac, v.stawidth, v.stadistinct,
              '1', '1', '1', '1',
              '1',
              v.staop1, v.staop2, v.staop3, v.staop4,
              v.staop5,
              v.stanumbers1, v.stanumbers2, v.stanumbers3, v.stanumbers4,
              v.stanumbers5,
              v.stavalues1, v.stavalues2, v.stavalues3, v.stavalues4
             ,v.stavalues5
              ), (
              s.starelid::regclass, s.staattnum, s.stainherit,
              s.stanullfrac, s.stawidth, s.stadistinct,
              '1', '1', '1', '1',
              '1',
              s.staop1, s.staop2, s.staop3, s.staop4,
              s.staop5,
              s.stanumbers1, s.stanumbers2, s.stanumbers3, s.stanumbers4,
              s.stanumbers5,
              s.stavalues1, s.stavalues2, s.stavalues3, s.stavalues4
             ,s.stavalues5
              ))
         FROM dbms_stats._column_stats_locked v,
              pg_statistic s
        WHERE v.starelid = 'st0'::regclass
          AND v.staattnum = '2'::int2
          AND s.starelid = 'st0'::regclass
          AND s.staattnum = '1'::int2) m;

-- No.5-1-20
SELECT (m.merge).starelid::regclass,
       (m.merge).staattnum,
       (m.merge).stainherit,
       (m.merge).stanullfrac,
       (m.merge).stawidth,
       (m.merge).stadistinct,
       (m.merge).stakind1,
       (m.merge).stakind2,
       (m.merge).stakind3,
       (m.merge).stakind4,
       (m.merge).stakind5,
       (m.merge).staop1,
       (m.merge).staop2,
       (m.merge).staop3,
       (m.merge).staop4,
       (m.merge).staop5,
       (m.merge).stanumbers1,
       (m.merge).stanumbers2,
       (m.merge).stanumbers3,
       (m.merge).stanumbers4,
       (m.merge).stanumbers5,
       (m.merge).stavalues1,
       (m.merge).stavalues2,
       (m.merge).stavalues3,
       (m.merge).stavalues4
      ,(m.merge).stavalues5
 FROM (SELECT dbms_stats.merge((v.starelid::regclass, v.staattnum, v.stainherit,
              v.stanullfrac, v.stawidth, v.stadistinct,
              '2', '2', '2', '2',
              '2',
              v.staop1, v.staop2, v.staop3, v.staop4,
              v.staop5,
              v.stanumbers1, v.stanumbers2, v.stanumbers3, v.stanumbers4,
              v.stanumbers5,
              v.stavalues1, v.stavalues2, v.stavalues3, v.stavalues4
             ,v.stavalues5
              ), (
              s.starelid::regclass, s.staattnum, s.stainherit,
              s.stanullfrac, s.stawidth, s.stadistinct,
              '2', '2', '2', '2',
              '2',
              s.staop1, s.staop2, s.staop3, s.staop4,
              s.staop5,
              s.stanumbers1, s.stanumbers2, s.stanumbers3, s.stanumbers4,
              s.stanumbers5,
              s.stavalues1, s.stavalues2, s.stavalues3, s.stavalues4
             ,s.stavalues5
              ))
         FROM dbms_stats._column_stats_locked v,
              pg_statistic s
        WHERE v.starelid = 'st0'::regclass
          AND v.staattnum = '2'::int2
          AND s.starelid = 'st0'::regclass
          AND s.staattnum = '1'::int2) m;

-- No.5-1-21
SELECT dbms_stats.merge((v.starelid::regclass, '2', v.stainherit,
              v.stanullfrac, v.stawidth, v.stadistinct,
              '1', '1', '1', '1',
              '1',
              v.staop1, v.staop2, v.staop3, v.staop4,
              v.staop5,
              v.stanumbers1, v.stanumbers2, v.stanumbers3, v.stanumbers4,
              v.stanumbers5,
              v.stavalues1, v.stavalues2, v.stavalues3, v.stavalues4
             ,v.stavalues5
              ), (
              s.starelid::regclass, s.staattnum, s.stainherit,
              s.stanullfrac, s.stawidth, s.stadistinct,
              '1', '1', '1', '1',
              '1',
              s.staop1, s.staop2, s.staop3, s.staop4,
              s.staop5,
              s.stanumbers1, s.stanumbers2, s.stanumbers3, s.stanumbers4,
              s.stanumbers5,
              s.stavalues1, s.stavalues2, s.stavalues3, s.stavalues4
             ,s.stavalues5
              ))
         FROM dbms_stats._column_stats_locked v,
              pg_statistic s
        WHERE v.starelid = 'st0'::regclass
          AND v.staattnum = '1'::int2
          AND s.starelid = 'st0'::regclass
          AND s.staattnum = '1'::int2;

-- No.5-1-22
SELECT dbms_stats.merge((v.starelid::regclass, '2', v.stainherit,
              v.stanullfrac, v.stawidth, v.stadistinct,
              '2', '2', '2', '2',
              '2',
              v.staop1, v.staop2, v.staop3, v.staop4,
              v.staop5,
              v.stanumbers1, v.stanumbers2, v.stanumbers3, v.stanumbers4,
              v.stanumbers5,
              v.stavalues1, v.stavalues2, v.stavalues3, v.stavalues4
             ,v.stavalues5
              ), (
              s.starelid::regclass, s.staattnum, s.stainherit,
              s.stanullfrac, s.stawidth, s.stadistinct,
              '2', '2', '2', '2',
              '2',
              s.staop1, s.staop2, s.staop3, s.staop4,
              s.staop5,
              s.stanumbers1, s.stanumbers2, s.stanumbers3, s.stanumbers4,
              s.stanumbers5,
              s.stavalues1, s.stavalues2, s.stavalues3, s.stavalues4
             ,s.stavalues5
              ))
         FROM dbms_stats._column_stats_locked v,
              pg_statistic s
        WHERE v.starelid = 'st0'::regclass
          AND v.staattnum = '1'::int2
          AND s.starelid = 'st0'::regclass
          AND s.staattnum = '1'::int2;
RESET client_min_messages;
SELECT dbms_stats.unlock_database_stats();

/*
 * No.6-4 dbms_stats.is_target_relkind
 */
-- No.6-4-10
SELECT dbms_stats.is_target_relkind('f');

/*
 * No.7-1 dbms_stats.backup
 */
DELETE FROM dbms_stats.backup_history;
INSERT INTO dbms_stats.backup_history(id, time, unit) values(1, '2012-01-01', 'd');
-- No.7-1-9
SELECT dbms_stats.backup(1, 's0.sft0'::regclass, NULL);
SELECT count(*) FROM dbms_stats.relation_stats_backup;
SELECT count(*) FROM dbms_stats.column_stats_backup;

-- No.7-1-12
DELETE FROM dbms_stats.relation_stats_backup;
SELECT dbms_stats.backup(1, NULL, 1::int2);
SELECT relid::regclass FROM dbms_stats.relation_stats_backup
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, staattnum FROM dbms_stats.column_stats_backup
 GROUP BY starelid, staattnum
 ORDER BY starelid, staattnum;

-- No.7-1-14
DELETE FROM dbms_stats.relation_stats_backup;
SELECT dbms_stats.backup(1, NULL::regclass, NULL);
SELECT relid::regclass FROM dbms_stats.relation_stats_backup
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, staattnum FROM dbms_stats.column_stats_backup
 GROUP BY starelid, staattnum
 ORDER BY starelid, staattnum;

-- No.7-1-18
DELETE FROM dbms_stats.relation_stats_backup;
\! psql contrib_regression -c "SELECT dbms_stats.backup(NULL, 's0.st0'::regclass, NULL)" > results/ut_no2_1_17.out 2>&1
SELECT count(*) FROM dbms_stats.relation_stats_backup;
SELECT count(*) FROM dbms_stats.column_stats_backup;

/*
 * No.8-1 dbms_stats.backup
 */
SELECT setval('dbms_stats.backup_history_id_seq',1, false);
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

-- No.8-1-1
DELETE FROM dbms_stats.backup_history;
SELECT dbms_stats.backup('s0.st0'::regclass, 'id', 'dummy comment');
SELECT id, unit, comment FROM dbms_stats.backup_history;

-- No.8-1-2
DELETE FROM dbms_stats.backup_history;
SELECT dbms_stats.backup('s0.st0'::regclass, NULL, 'dummy comment');
SELECT id, unit, comment FROM dbms_stats.backup_history;

-- No.8-1-3
DELETE FROM dbms_stats.backup_history;
SELECT dbms_stats.backup(NULL::regclass, 'id', 'dummy comment');
SELECT id, unit, comment FROM dbms_stats.backup_history;

-- No.8-1-4
DELETE FROM dbms_stats.backup_history;
SELECT dbms_stats.backup(NULL::regclass, NULL, 'dummy comment');
SELECT id, unit, comment FROM dbms_stats.backup_history;

-- No.8-1-5
DELETE FROM dbms_stats.backup_history;
SELECT dbms_stats.backup(0, NULL, 'dummy comment');
SELECT id, unit, comment FROM dbms_stats.backup_history;

-- No.8-1-6
DELETE FROM dbms_stats.backup_history;
SELECT dbms_stats.backup('s0.st0'::regclass, NULL, 'dummy comment');
SELECT id, unit, comment FROM dbms_stats.backup_history;

-- No.8-1-7
DELETE FROM dbms_stats.backup_history;
SELECT dbms_stats.backup(
    'pg_toast.pg_toast_2618'::regclass,
    NULL,
    'dummy comment');
SELECT id, unit, comment FROM dbms_stats.backup_history;

-- No.8-1-8
DELETE FROM dbms_stats.backup_history;
SELECT dbms_stats.backup('s0.st0_idx'::regclass, NULL, 'dummy comment');
SELECT id, unit, comment FROM dbms_stats.backup_history;

-- No.8-1-9
DELETE FROM dbms_stats.backup_history;
SELECT dbms_stats.backup('s0.ss0'::regclass, NULL, 'dummy comment');
SELECT id, unit, comment FROM dbms_stats.backup_history;

-- No.8-1-10
DELETE FROM dbms_stats.backup_history;
SELECT dbms_stats.backup('s0.sc0'::regclass, NULL, 'dummy comment');
SELECT id, unit, comment FROM dbms_stats.backup_history;

-- No.8-1-11
DELETE FROM dbms_stats.backup_history;
SELECT dbms_stats.backup('s0.sft0'::regclass, NULL, 'dummy comment');
SELECT id, unit, comment FROM dbms_stats.backup_history;

-- No.8-1-13
DELETE FROM dbms_stats.backup_history;
SELECT dbms_stats.backup('pg_catalog.pg_class'::regclass, NULL, 'dummy comment');
SELECT id, unit, comment FROM dbms_stats.backup_history;

-- No.8-1-14
DELETE FROM dbms_stats.backup_history;
SELECT dbms_stats.backup('s0.st0'::regclass, 'dummy', 'dummy comment');
SELECT id, unit, comment FROM dbms_stats.backup_history;

-- No.8-1-15
DELETE FROM dbms_stats.backup_history;
DELETE FROM pg_statistic
 WHERE starelid = 's0.st0'::regclass
   AND staattnum = 1::int2;
SELECT count(*) FROM dbms_stats.column_stats_effective
 WHERE starelid = 's0.st0'::regclass
   AND staattnum = 1::int2;
SELECT dbms_stats.backup('s0.st0'::regclass, 'id', 'dummy comment');
SELECT id, unit, comment FROM dbms_stats.backup_history;

/*
 * Stab function dbms_stats.backup
 */
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
 * No.8-3 dbms_stats.backup_schema_stats
 */
SELECT setval('dbms_stats.backup_history_id_seq',9, false);
-- No.8-3-1
SELECT dbms_stats.backup_schema_stats('s0', 'comment');
SELECT id, unit, comment FROM dbms_stats.backup_history
 ORDER BY id DESC
 LIMIT 1;
-- No.8-3-2
SELECT dbms_stats.backup_schema_stats('s00', 'comment');
SELECT id, unit, comment FROM dbms_stats.backup_history
 ORDER BY id DESC
 LIMIT 1;
-- No.8-3-3
SELECT dbms_stats.backup_schema_stats('pg_catalog', 'comment');
SELECT id, unit, comment FROM dbms_stats.backup_history
 ORDER BY id DESC
 LIMIT 1;

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
SELECT * FROM relations_backup_v;
SELECT * FROM columns_backup_v;

VACUUM ANALYZE;

/*
 * No.9-1 dbms_stats.restore
 */
-- No.9-1-1
DELETE FROM dbms_stats._relation_stats_locked;
BEGIN;
SELECT relation::regclass, mode
 FROM pg_locks l join pg_class c on (l.relation = c.oid and c.relkind = 'r')
 WHERE mode LIKE '%ExclusiveLock%'
 ORDER BY relation::regclass::text, mode;
SELECT dbms_stats.restore(2, 's0.st0', NULL);
SELECT relation::regclass, mode
 FROM pg_locks l join pg_class c on (l.relation = c.oid and c.relkind = 'r')
 WHERE mode LIKE '%ExclusiveLock%'
 ORDER BY relation::regclass::text, mode;
COMMIT;
SELECT relid::regclass FROM dbms_stats.relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid, attname, stainherit FROM columns_locked_v c;

-- No.9-1-2
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.restore(2, 'st0', NULL);
SELECT relid::regclass FROM dbms_stats.relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid, attname, stainherit FROM columns_locked_v c;

-- No.9-1-3
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.restore(2, 's00.s0', NULL);
SELECT count(*) FROM dbms_stats.column_stats_locked;
SELECT count(*) FROM dbms_stats.relation_stats_locked;

-- No.9-1-4
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.restore(NULL, 's0.st0', NULL);
SELECT count(*) FROM dbms_stats.column_stats_locked;
SELECT count(*) FROM dbms_stats.relation_stats_locked;

-- No.9-1-5
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.restore(2, 's0.st0', 'id');
SELECT relid::regclass FROM dbms_stats.relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid, attname, stainherit FROM columns_locked_v c;

-- No.9-1-6
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.restore(2, NULL, 'id');
SELECT count(*) FROM dbms_stats.column_stats_locked;
SELECT count(*) FROM dbms_stats.relation_stats_locked;

-- No.9-1-7
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.restore(2, 's0.st0', NULL);
SELECT relid::regclass FROM dbms_stats.relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid, attname, stainherit FROM columns_locked_v c;

-- No.9-1-8
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.restore(2, NULL, NULL);
SELECT relid::regclass FROM dbms_stats.relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid, attname, stainherit FROM columns_locked_v c;

-- No.9-1-9
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.restore(0, 's0.st0', NULL);
SELECT relid::regclass FROM dbms_stats.relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid, attname, stainherit FROM columns_locked_v c;

-- No.9-1-10
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.restore(2, 0, 'id');
SELECT count(*) FROM dbms_stats.column_stats_locked;
SELECT count(*) FROM dbms_stats.relation_stats_locked;

-- No.9-1-11
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.restore(1, 's0.st0', NULL);
SELECT count(*) FROM dbms_stats.column_stats_locked;
SELECT count(*) FROM dbms_stats.relation_stats_locked;

-- No.9-1-12
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.restore(2, 's0.st0', 'dummy');
SELECT count(*) FROM dbms_stats.column_stats_locked;
SELECT count(*) FROM dbms_stats.relation_stats_locked;

-- No.9-1-13
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.restore(1, 's0.st0', 'id');
SELECT count(*) FROM dbms_stats.column_stats_locked;
SELECT count(*) FROM dbms_stats.relation_stats_locked;

-- No.9-1-15
DELETE FROM dbms_stats._relation_stats_locked;
ALTER TABLE s1.st0 DROP COLUMN id;
SELECT dbms_stats.restore(2, 's1.st0', 'id');
SELECT relid::regclass FROM dbms_stats.relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid, attname, stainherit FROM columns_locked_v c;

-- No.9-1-14
DELETE FROM dbms_stats._relation_stats_locked;
\set s1_st0_oid `psql contrib_regression -tA -c "SELECT c.oid FROM pg_class c, pg_namespace n WHERE c.relnamespace = n.oid AND n.nspname = 's1' AND c.relname = 'st0';"`
DROP TABLE s1.st0;
-- SELECT dbms_stats.restore(2, :s1_st0_oid, NULL);
-- To avoid test unstability caused by relation id alloction, the test
-- above is omitted.

SELECT count(*) FROM dbms_stats.relation_stats_locked;
SELECT count(*) FROM dbms_stats.column_stats_locked;
CREATE TABLE s1.st0(id integer, num integer);
INSERT INTO s1.st0 VALUES (1, 15), (2, 25), (3, 35), (4, 45);
VACUUM ANALYZE;
-- No.9-1-16
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.restore(2, 's0.st0', NULL);
SELECT relid::regclass FROM dbms_stats.relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid, attname, stainherit FROM columns_locked_v c;

-- No.9-1-17
DELETE FROM dbms_stats._relation_stats_locked;
INSERT INTO dbms_stats.relation_stats_backup(
               id, relid, relname, relpages, reltuples,
               relallvisible,
               curpages)
     VALUES (2,
             'pg_toast.pg_toast_2618'::regclass,
             'pg_toast.pg_toast_2618', 1, 1,
             1,
             1);
SELECT * FROM relations_backup_v
 WHERE id = 2
   AND relname = 'pg_toast.pg_toast_2618';
SELECT dbms_stats.restore(2, 'pg_toast.pg_toast_2618', NULL);
SELECT count(*) FROM dbms_stats.column_stats_locked;
SELECT count(*) FROM dbms_stats.relation_stats_locked;
DELETE FROM dbms_stats.relation_stats_backup
 WHERE id = 2
   AND relname = 'pg_toast.pg_toast_2618';

-- No.9-1-18
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.restore(2, 's0.st0_idx', NULL);
SELECT relid::regclass FROM dbms_stats.relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid, attname, stainherit FROM columns_locked_v c;

-- No.9-1-19
DELETE FROM dbms_stats._relation_stats_locked;
INSERT INTO dbms_stats.relation_stats_backup(
               id, relid, relname, relpages, reltuples,
               relallvisible,
               curpages)
     VALUES (2, 's0.ss0'::regclass, 's0.ss0', 1, 1,
             1,
             1);
SELECT * FROM relations_backup_v
 WHERE id = 2
   AND relname = 's0.ss0';
SELECT dbms_stats.restore(2, 's0.ss0', NULL);
SELECT count(*) FROM dbms_stats.column_stats_locked;
SELECT count(*) FROM dbms_stats.relation_stats_locked;
DELETE FROM dbms_stats.relation_stats_backup
 WHERE id = 2
   AND relname = 's0.ss0';

-- No.9-1-20
DELETE FROM dbms_stats._relation_stats_locked;
INSERT INTO dbms_stats.relation_stats_backup(
               id, relid, relname, relpages, reltuples,
               relallvisible,
               curpages)
     VALUES (2, 's0.sc0'::regclass, 's0.sc0', 1, 1,
             1,
             1);
SELECT * FROM relations_backup_v
 WHERE id = 2
   AND relname = 's0.sc0';
SELECT dbms_stats.restore(2, 's0.sc0', NULL);
SELECT count(*) FROM dbms_stats.column_stats_locked;
SELECT count(*) FROM dbms_stats.relation_stats_locked;
DELETE FROM dbms_stats.relation_stats_backup
 WHERE id = 2
   AND relname = 's0.sc0';

-- No.9-1-21
DELETE FROM dbms_stats._relation_stats_locked;
INSERT INTO dbms_stats.relation_stats_backup(
               id, relid, relname, relpages, reltuples,
               relallvisible,
               curpages)
     VALUES (3, 's0.sft0'::regclass, 's0.sft0', 1, 1,
             1,
             1);
SELECT * FROM relations_backup_v
 WHERE id = 3
   AND relname = 's0.sft0';
SELECT dbms_stats.restore(2, 's0.sft0', NULL);
SELECT count(*) FROM dbms_stats.column_stats_locked;
SELECT count(*) FROM dbms_stats.relation_stats_locked;
DELETE FROM dbms_stats.relation_stats_backup
 WHERE id = 3
   AND relname = 's0.sft0';

-- No.9-1-23
DELETE FROM dbms_stats._relation_stats_locked;
INSERT INTO dbms_stats.relation_stats_backup(
               id, relid, relname, relpages, reltuples,
               relallvisible,
               curpages)
     VALUES (2, 'pg_catalog.pg_class'::regclass, 'pg_catalog.pg_class', 1, 1,
             1,
             1);
SELECT * FROM relations_backup_v
 WHERE id = 2
   AND relname = 'pg_catalog.pg_class';
SELECT dbms_stats.restore(2, 'pg_catalog.pg_class', NULL);
SELECT count(*) FROM dbms_stats.column_stats_locked;
SELECT count(*) FROM dbms_stats.relation_stats_locked;
DELETE FROM dbms_stats.relation_stats_backup
 WHERE id = 2
   AND relname = 'pg_catalog.pg_class';

-- No.9-1-24
DELETE FROM dbms_stats._relation_stats_locked;
INSERT INTO dbms_stats._relation_stats_locked(relid, relname)
    VALUES ('s0.st0'::regclass, 's0.st0');
INSERT INTO dbms_stats._column_stats_locked(starelid, staattnum, stainherit)
     SELECT starelid::regclass, staattnum, stainherit
       FROM dbms_stats.column_stats_effective
      WHERE starelid = 's0.st0'::regclass;
SELECT id, unit, comment FROM dbms_stats.backup_history
 WHERE id = 2;
SELECT * FROM columns_locked_v;
SELECT * FROM relations_locked_v;
SELECT dbms_stats.restore(2, 's0.st0', NULL);
SELECT * FROM relations_locked_v;
SELECT * FROM columns_locked_v;

-- No.9-1-25
DELETE FROM dbms_stats._relation_stats_locked;
SELECT id, unit, comment FROM dbms_stats.backup_history
 WHERE id = 2;
SELECT dbms_stats.restore(2, 's0.st0', NULL);
SELECT * FROM relations_locked_v;
SELECT * FROM columns_locked_v;

/*
 * Stab function dbms_stats.restore
 */
CREATE OR REPLACE FUNCTION dbms_stats.restore(
    backup_id int8,
    relid regclass DEFAULT NULL,
    attname text DEFAULT NULL)
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
 * No.10-1 dbms_stats.restore_database_stats
 */
-- No.10-1-1
SELECT dbms_stats.restore_database_stats('2012-02-29 23:59:57');
-- No.10-1-2
SELECT dbms_stats.restore_database_stats('2012-02-29 23:59:57.000002');
-- No.10-1-3
SELECT dbms_stats.restore_database_stats('2012-01-01 00:00:00');
--#No.10-1-4 is skipped after lock tests
--#No.10-1-5 is skipped after lock tests
-- No.10-1-6
SELECT dbms_stats.restore_database_stats('2012-02-29 23:59:57');

/*
 * No.10-2 dbms_stats.restore_schema_stats
 */
-- No.10-2-1
SELECT dbms_stats.restore_schema_stats('s0', '2012-02-29 23:59:57');
-- No.10-2-2
SELECT dbms_stats.restore_schema_stats('s0', '2012-02-29 23:59:57.000002');
-- No.10-2-3
SELECT dbms_stats.restore_schema_stats('s0', '2012-01-01 00:00:00');
--#No.10-2-4 is skipped after lock tests
--#No.10-2-5 is skipped after lock tests
-- No.10-2-6
SELECT dbms_stats.restore_schema_stats('s0', '2012-02-29 23:59:57');
-- No.10-2-7
SELECT dbms_stats.restore_schema_stats('s0', '2012-02-29 23:59:57');
--#No.10-2-8 is skipped after lock tests
-- No.10-2-9
SELECT dbms_stats.restore_schema_stats('s00', '2012-02-29 23:59:57');
-- No.10-2-10
SELECT dbms_stats.restore_schema_stats('pg_catalog', '2012-02-29 23:59:57');

/*
 * No.10-7 dbms_stats.restore_stats
 */
-- No.10-7-1
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.restore_stats(NULL);

-- No.10-7-2
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.restore_stats(0);

-- No.10-7-3
DELETE FROM dbms_stats._relation_stats_locked;
BEGIN;
SELECT relation::regclass, mode
 FROM pg_locks l join pg_class c on (l.relation = c.oid and c.relkind = 'r')
 WHERE mode LIKE '%ExclusiveLock%'
 ORDER BY relation::regclass::text, mode;
SELECT dbms_stats.restore_stats(2);
SELECT relation::regclass, mode
 FROM pg_locks l join pg_class c on (l.relation = c.oid and c.relkind = 'r')
 WHERE mode LIKE '%ExclusiveLock%'
 ORDER BY relation::regclass::text, mode;
COMMIT;
SELECT relid::regclass FROM dbms_stats.relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid, attname, stainherit FROM columns_locked_v c;

-- No.10-7-4
DELETE FROM dbms_stats._relation_stats_locked;
INSERT INTO dbms_stats._relation_stats_locked(relid, relname)
     SELECT relid::regclass, relname
       FROM dbms_stats.relation_stats_effective;
INSERT INTO dbms_stats._column_stats_locked(starelid, staattnum, stainherit)
     SELECT starelid::regclass, staattnum, stainherit
       FROM dbms_stats.column_stats_effective;
SELECT id, unit, comment FROM dbms_stats.backup_history
 WHERE id = 8;
SELECT * FROM columns_locked_v;
SELECT * FROM relations_locked_v;
SELECT dbms_stats.restore_stats(8);
SELECT * FROM relations_locked_v;
SELECT * FROM columns_locked_v;

-- No.10-7-5
DELETE FROM dbms_stats._relation_stats_locked;
SELECT id, unit, comment FROM dbms_stats.backup_history
 WHERE id = 8;
SELECT dbms_stats.restore_stats(8);
SELECT * FROM relations_locked_v;
SELECT * FROM columns_locked_v;

/*
 * No.11-1 dbms_stats.lock(relid, attname)
 */
-- No.11-1-1
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock(NULL, NULL);
-- No.11-1-2
ALTER FUNCTION dbms_stats.lock(relid regclass)
    RENAME TO truth_lock;
CREATE FUNCTION dbms_stats.lock(relid regclass)
RETURNS regclass AS
$$
BEGIN
	RAISE NOTICE 'arguments are %', $1;
	RETURN $1;
END
$$
LANGUAGE plpgsql;
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock('s0.st0', NULL);
DROP FUNCTION dbms_stats.lock(relid regclass);
ALTER FUNCTION dbms_stats.truth_lock(relid regclass)
    RENAME TO lock;
-- No.11-1-3
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock(NULL, 'id');
-- No.11-1-4
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock('s0.st0', 'id');
SELECT * FROM relations_locked_v;
SELECT * FROM columns_locked_v c;
-- No.11-1-5
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock(0, 'id');
-- No.11-1-6
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock('s0.st0', 'id');
SELECT * FROM relations_locked_v;
SELECT * FROM columns_locked_v c;
-- No.11-1-7
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock('pg_toast.pg_toast_2618', 'id');
-- No.11-1-8
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock('s0.st0_idx', 'id');
-- No.11-1-9
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock('st1_exp', 'lower');
SELECT * FROM relations_locked_v;
SELECT * FROM columns_locked_v c;
DELETE FROM dbms_stats._relation_stats_locked;

-- No.11-1-10
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock('s0.ss0', 'id');
-- No.11-1-11
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock('s0.sc0', 'id');
-- No.11-1-12
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock('s0.sft0', 'id');
SELECT * FROM relations_locked_v;
SELECT * FROM columns_locked_v c;
-- No.11-1-14
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock('pg_catalog.pg_class', 'id');
-- No.11-1-15
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock('s0.st0', 'dummy');
-- No.11-1-16
DELETE FROM dbms_stats._relation_stats_locked;
DELETE FROM pg_statistic
 WHERE starelid = 's0.st0'::regclass;
SELECT dbms_stats.lock('s0.st0', 'id');
VACUUM ANALYZE;
-- No.11-1-17
DELETE FROM dbms_stats._relation_stats_locked;
INSERT INTO dbms_stats._relation_stats_locked(
    relid, relname, relpages, reltuples,
    relallvisible,
    curpages)
    VALUES('s0.st0'::regclass, 's0.st0', 1, 1640,
           1,
           1);
SELECT dbms_stats.lock_column_stats('s0.st0','id');
UPDATE dbms_stats._column_stats_locked
   SET (stanullfrac, stawidth, stadistinct,
        stakind1, stakind2, stakind3, stakind4,
        stakind5,
        staop1, staop2, staop3, staop4,
        staop5,
        stanumbers1, stanumbers2, stanumbers3, stanumbers4,
        stanumbers5,
        stavalues1, stavalues2, stavalues3, stavalues4
       ,stavalues5
       ) = (
        NULL, NULL, NULL,
        NULL, NULL, NULL, NULL,
        NULL, NULL, NULL, NULL,
        NULL, NULL, NULL, NULL,
        NULL, NULL, NULL, NULL,
        NULL, NULL, NULL, NULL)
 WHERE starelid = 's0.st0'::regclass;
SELECT dbms_stats.lock('s0.st0', 'id');
SELECT * FROM relations_locked_v;
SELECT * FROM columns_locked_v c;
-- No.11-1-18
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock('s0.st0', 'id');
SELECT * FROM relations_locked_v
 WHERE relid = 's0.st0'::regclass;
SELECT starelid, attname, stainherit FROM columns_locked_v c;

/*
 * No.11-2 dbms_stats.lock(relid)
 */
-- No.11-2-1
DELETE FROM dbms_stats._relation_stats_locked;
BEGIN;
SELECT relation::regclass, mode
 FROM pg_locks l join pg_class c on (l.relation = c.oid and c.relkind = 'r')
 WHERE mode LIKE '%ExclusiveLock%'
 ORDER BY relation::regclass::text, mode;
SELECT dbms_stats.lock('s0.st0');
SELECT * FROM relations_locked_v;
SELECT * FROM columns_locked_v c;
SELECT relation::regclass, mode
 FROM pg_locks l join pg_class c on (l.relation = c.oid and c.relkind = 'r')
 WHERE mode LIKE '%ExclusiveLock%'
 ORDER BY relation::regclass::text, mode;
COMMIT;

-- No.11-2-2
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock(NULL);
-- No.11-2-3
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock('0');
-- No.11-2-4
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock('s0.st0');
SELECT * FROM relations_locked_v;
SELECT * FROM columns_locked_v c;
-- No.11-2-5
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock('pg_toast.pg_toast_2618');
-- No.11-2-6
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock('s0.st0_idx');
SELECT * FROM relations_locked_v;
SELECT * FROM columns_locked_v c;
-- No.11-2-7
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock('s0.ss0');
-- No.11-2-8
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock('s0.sc0');
-- No.11-2-9
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock('s0.sft0');
SELECT * FROM relations_locked_v;
SELECT * FROM columns_locked_v c;
-- No.11-2-11
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock('pg_catalog.pg_class');
-- No.11-2-12
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_table_stats('s0.st0');
UPDATE dbms_stats._relation_stats_locked
   SET (relpages, reltuples,
        relallvisible,
        curpages)
     = (NULL, NULL, NULL
       ,NULL
       )
 WHERE relid = 's0.st0'::regclass;
SELECT dbms_stats.lock('s0.st0');
SELECT * FROM relations_locked_v;
SELECT * FROM columns_locked_v c;
-- No.11-2-13
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock('s0.st0');
SELECT * FROM relations_locked_v;
SELECT * FROM columns_locked_v c;

/*
 * Stab function dbms_stats.lock
 */
ALTER FUNCTION dbms_stats.lock(relid regclass)
    RENAME TO truth_lock;
CREATE FUNCTION dbms_stats.lock(relid regclass)
RETURNS regclass AS
$$
BEGIN
    RAISE NOTICE 'arguments are %', $1;
    RETURN $1;
END
$$
LANGUAGE plpgsql;

ALTER FUNCTION dbms_stats.lock(relid regclass, attname text)
    RENAME TO truth_lock;
CREATE FUNCTION dbms_stats.lock(
    relid regclass,
    attname text)
RETURNS regclass AS
$$
BEGIN
    RAISE NOTICE 'arguments are %, %', $1, $2;
    RETURN $1;
END
$$
LANGUAGE plpgsql;

/*
 * No.12-1 dbms_stats.lock_database_stats
 */
-- No.12-1-1
SELECT dbms_stats.lock_database_stats();

/*
 * No.12-2 dbms_stats.lock_schema_stats
 */
-- No.12-2-1
SELECT dbms_stats.lock_schema_stats('s0');
-- No.12-2-2
SELECT dbms_stats.lock_schema_stats('s00');
-- No.12-2-3
SELECT dbms_stats.lock_schema_stats('pg_catalog');

/*
 * No.12-3 dbms_stats.lock_table_stats(regclass)
 */
-- No.12-3-1
SELECT dbms_stats.lock_table_stats('s0.st0');
-- No.12-3-2
SELECT dbms_stats.lock_table_stats('st0');
-- No.12-3-3
SELECT dbms_stats.lock_table_stats('s00.s0');

/*
 * No.12-4 dbms_stats.lock_table_stats(schemaname, tablename)
 */
-- No.12-4-1
SELECT dbms_stats.lock_table_stats('s0', 'st0');

/*
 * No.12-5 dbms_stats.lock_column_stats(regclass, attname)
 */
-- No.12-5-1
SELECT dbms_stats.lock_column_stats('s0.st0', 'id');
-- No.12-5-2
SELECT dbms_stats.lock_column_stats('st0', 'id');
-- No.12-5-3
SELECT dbms_stats.lock_column_stats('s00.s0', 'id');

/*
 * No.12-6 dbms_stats.lock_column_stats(schemaname, tablename, int2)
 */
-- No.12-6-1
SELECT dbms_stats.lock_column_stats('s0', 'st0', 'id');

/*
 * Delete Stab function lock
 */
DROP FUNCTION dbms_stats.lock(relid regclass);
ALTER FUNCTION dbms_stats.truth_lock(relid regclass)
    RENAME TO lock;
DROP FUNCTION dbms_stats.lock(relid regclass, attname text);
ALTER FUNCTION dbms_stats.truth_lock(relid regclass, attname text)
    RENAME TO lock;

/*
 * No.13-1 dbms_stats.unlock
 */
-- No.13-1-1
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT * FROM dbms_stats.backup_history
 ORDER BY id;
SELECT count(*) FROM dbms_stats.relation_stats_backup;
SELECT count(*) FROM dbms_stats.column_stats_backup;
SELECT dbms_stats.unlock();
SELECT count(*) FROM dbms_stats._relation_stats_locked;
SELECT count(*) FROM dbms_stats._column_stats_locked;
SELECT * FROM dbms_stats.backup_history
 ORDER BY id;
SELECT count(*) FROM dbms_stats.relation_stats_backup;
SELECT count(*) FROM dbms_stats.column_stats_backup;

-- No.13-1-2
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT dbms_stats.unlock();
SELECT count(*) FROM dbms_stats._relation_stats_locked;
SELECT count(*) FROM dbms_stats._column_stats_locked;

-- No.13-1-3
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
DELETE FROM dbms_stats._column_stats_locked;
SELECT dbms_stats.unlock();
SELECT count(*) FROM dbms_stats._relation_stats_locked;
SELECT count(*) FROM dbms_stats._column_stats_locked;

-- No.13-1-4
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.unlock();
SELECT count(*) FROM dbms_stats._relation_stats_locked;
SELECT count(*) FROM dbms_stats._column_stats_locked;

-- No.13-1-5
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;
SELECT dbms_stats.unlock('s0.st0');
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;

-- No.13-1-6
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;
SELECT dbms_stats.unlock('st0');
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;

-- No.13-1-7
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT count(*) FROM dbms_stats._relation_stats_locked;
SELECT count(*) FROM dbms_stats._column_stats_locked;
SELECT dbms_stats.unlock('s00.s0');
SELECT count(*) FROM dbms_stats._relation_stats_locked;
SELECT count(*) FROM dbms_stats._column_stats_locked;

-- No.13-1-8
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT dbms_stats.unlock('s0.st0', 'id');
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid, attname, stainherit FROM columns_locked_v c;

-- No.13-1-9
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT dbms_stats.unlock('s0.st0', 'dummy');
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid, attname, stainherit FROM columns_locked_v c;

-- No.13-1-10
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
DELETE FROM dbms_stats._column_stats_locked;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT dbms_stats.unlock('s0.st0', 'id');
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, staattnum FROM dbms_stats._column_stats_locked
 GROUP BY starelid, staattnum
 ORDER BY starelid;

-- No.13-1-11
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, staattnum FROM dbms_stats._column_stats_locked
 GROUP BY starelid, staattnum
 ORDER BY starelid;
SELECT dbms_stats.unlock(NULL, 'id');
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, staattnum FROM dbms_stats._column_stats_locked
 GROUP BY starelid, staattnum
 ORDER BY starelid;

-- No.13-1-12
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, staattnum FROM dbms_stats._column_stats_locked
 GROUP BY starelid, staattnum
 ORDER BY starelid;
SELECT dbms_stats.unlock('s0.st0', NULL);
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, staattnum FROM dbms_stats._column_stats_locked
 GROUP BY starelid, staattnum
 ORDER BY starelid;

-- No.13-1-13
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT count(*) FROM dbms_stats._relation_stats_locked;
SELECT count(*) FROM dbms_stats._column_stats_locked;
BEGIN;
SELECT relation::regclass, mode
 FROM pg_locks l join pg_class c on (l.relation = c.oid and c.relkind = 'r')
 WHERE mode LIKE '%ExclusiveLock%'
 ORDER BY relation::regclass::text, mode;
SELECT dbms_stats.unlock();
SELECT relation::regclass, mode
 FROM pg_locks l join pg_class c on (l.relation = c.oid and c.relkind = 'r')
 WHERE mode LIKE '%ExclusiveLock%'
 ORDER BY relation::regclass::text, mode;
COMMIT;
SELECT count(*) FROM dbms_stats._relation_stats_locked;
SELECT count(*) FROM dbms_stats._column_stats_locked;

/*
 * No.14-1 dbms_stats.unlock_database_stats
 */
-- No.14-1-1
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT * FROM dbms_stats.backup_history
 ORDER BY id;
SELECT count(*) FROM dbms_stats.relation_stats_backup;
SELECT count(*) FROM dbms_stats.column_stats_backup;
SELECT count(*) FROM dbms_stats._relation_stats_locked;
SELECT count(*) FROM dbms_stats._column_stats_locked;
SELECT dbms_stats.unlock_database_stats();
SELECT count(*) FROM dbms_stats._relation_stats_locked;
SELECT count(*) FROM dbms_stats._column_stats_locked;
SELECT * FROM dbms_stats.backup_history
 ORDER BY id;
SELECT count(*) FROM dbms_stats.relation_stats_backup;
SELECT count(*) FROM dbms_stats.column_stats_backup;

-- No.14-1-2
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
DELETE FROM dbms_stats._column_stats_locked;
SELECT count(*) FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.unlock_database_stats();
SELECT count(*) FROM dbms_stats._relation_stats_locked;
SELECT count(*) FROM dbms_stats._column_stats_locked;

-- No.14-1-3
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.unlock_database_stats();
SELECT count(*) FROM dbms_stats._relation_stats_locked;
SELECT count(*) FROM dbms_stats._column_stats_locked;

-- No.14-1-4
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT count(*) FROM dbms_stats._relation_stats_locked;
SELECT count(*) FROM dbms_stats._column_stats_locked;
BEGIN;
SELECT relation::regclass, mode
 FROM pg_locks l join pg_class c on (l.relation = c.oid and c.relkind = 'r')
 WHERE mode LIKE '%ExclusiveLock%'
 ORDER BY relation::regclass::text, mode;
SELECT dbms_stats.unlock_database_stats();
SELECT relation::regclass, mode
 FROM pg_locks l join pg_class c on (l.relation = c.oid and c.relkind = 'r')
 WHERE mode LIKE '%ExclusiveLock%'
 ORDER BY relation::regclass::text, mode;
COMMIT;
SELECT count(*) FROM dbms_stats._relation_stats_locked;
SELECT count(*) FROM dbms_stats._column_stats_locked;

/*
 * No.14-2 dbms_stats.unlock_schema_stats
 */
-- No.14-2-1
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT * FROM dbms_stats.backup_history
 ORDER BY id;
SELECT count(*) FROM dbms_stats.relation_stats_backup;
SELECT count(*) FROM dbms_stats.column_stats_backup;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;
SELECT dbms_stats.unlock_schema_stats('s0');
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;
SELECT * FROM dbms_stats.backup_history
 ORDER BY id;
SELECT count(*) FROM dbms_stats.relation_stats_backup;
SELECT count(*) FROM dbms_stats.column_stats_backup;

-- No.14-2-2
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
DELETE FROM dbms_stats._column_stats_locked;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;
SELECT dbms_stats.unlock_schema_stats('s0');
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;

-- No.14-2-3
DELETE FROM dbms_stats._relation_stats_locked;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;
SELECT dbms_stats.unlock_schema_stats('s0');
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;

-- No.14-2-4
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;
SELECT dbms_stats.unlock_schema_stats('s0');
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;

-- No.14-2-5
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;
SELECT dbms_stats.unlock_schema_stats('s00');
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;

-- No.14-2-6
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;
SELECT dbms_stats.unlock_schema_stats('pg_catalog');
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;

-- No.14-2-7
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;
SELECT dbms_stats.unlock_schema_stats(NULL);
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;

-- No.14-2-8
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;
BEGIN;
SELECT relation::regclass, mode
 FROM pg_locks l join pg_class c on (l.relation = c.oid and c.relkind = 'r')
 WHERE mode LIKE '%ExclusiveLock%'
 ORDER BY relation::regclass::text, mode;
SELECT dbms_stats.unlock_schema_stats('s0');
SELECT relation::regclass, mode
 FROM pg_locks l join pg_class c on (l.relation = c.oid and c.relkind = 'r')
 WHERE mode LIKE '%ExclusiveLock%'
 ORDER BY relation::regclass::text, mode;
COMMIT;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;

/*
 * No.14-3 dbms_stats.unlock_table_stats(regclass)
 */
-- No.14-3-1
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT * FROM dbms_stats.backup_history
 ORDER BY id;
SELECT count(*) FROM dbms_stats.relation_stats_backup;
SELECT count(*) FROM dbms_stats.column_stats_backup;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;
SELECT dbms_stats.unlock_table_stats('s0.st0');
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;
SELECT * FROM dbms_stats.backup_history
 ORDER BY id;
SELECT count(*) FROM dbms_stats.relation_stats_backup;
SELECT count(*) FROM dbms_stats.column_stats_backup;

-- No.14-3-2
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
DELETE FROM dbms_stats._column_stats_locked;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;
SELECT dbms_stats.unlock_table_stats('s0.st0');
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;

-- No.14-3-3
DELETE FROM dbms_stats._relation_stats_locked;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;
SELECT dbms_stats.unlock_table_stats('s0.st0');
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;

-- No.14-3-4
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;
SELECT dbms_stats.unlock_table_stats('s0.st0');
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;

-- No.14-3-5
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;
SELECT dbms_stats.unlock_table_stats('st0');
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;

-- No.14-3-6
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;
SELECT dbms_stats.unlock_table_stats('s00.s0');
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;

-- No.14-3-7
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;
SELECT dbms_stats.unlock_table_stats(NULL);
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;

-- No.14-3-8
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;
BEGIN;
SELECT relation::regclass, mode
 FROM pg_locks l join pg_class c on (l.relation = c.oid and c.relkind = 'r')
 WHERE mode LIKE '%ExclusiveLock%'
 ORDER BY relation::regclass::text, mode;
SELECT dbms_stats.unlock_table_stats('s0.st0');
SELECT relation::regclass, mode
 FROM pg_locks l join pg_class c on (l.relation = c.oid and c.relkind = 'r')
 WHERE mode LIKE '%ExclusiveLock%'
 ORDER BY relation::regclass::text, mode;
COMMIT;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;

/*
 * No.14-4 dbms_stats.unlock_table_stats(schemaname, tablename)
 */
-- No.14-4-1
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT * FROM dbms_stats.backup_history
 ORDER BY id;
SELECT count(*) FROM dbms_stats.relation_stats_backup;
SELECT count(*) FROM dbms_stats.column_stats_backup;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;
SELECT dbms_stats.unlock_table_stats('s0','st0');
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;
SELECT * FROM dbms_stats.backup_history
 ORDER BY id;
SELECT count(*) FROM dbms_stats.relation_stats_backup;
SELECT count(*) FROM dbms_stats.column_stats_backup;

-- No.14-4-2
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
DELETE FROM dbms_stats._column_stats_locked;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;
SELECT dbms_stats.unlock_table_stats('s0', 'st0');
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;

-- No.14-4-3
DELETE FROM dbms_stats._relation_stats_locked;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;
SELECT dbms_stats.unlock_table_stats('s0', 'st0');
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;

-- No.14-4-4
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;
SELECT dbms_stats.unlock_table_stats('s0', 'st0');
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;

-- No.14-4-5
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;
SELECT dbms_stats.unlock_table_stats('s00', 's0');
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;

-- No.14-4-6
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;
SELECT dbms_stats.unlock_table_stats(NULL, 'st0');
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;

-- No.14-4-7
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;
SELECT dbms_stats.unlock_table_stats('s0', NULL);
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;

-- No.14-4-8
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;
BEGIN;
SELECT relation::regclass, mode
 FROM pg_locks l join pg_class c on (l.relation = c.oid and c.relkind = 'r')
 WHERE mode LIKE '%ExclusiveLock%'
 ORDER BY relation::regclass::text, mode;
SELECT dbms_stats.unlock_table_stats('s0', 'st0');
SELECT relation::regclass, mode
 FROM pg_locks l join pg_class c on (l.relation = c.oid and c.relkind = 'r')
 WHERE mode LIKE '%ExclusiveLock%'
 ORDER BY relation::regclass::text, mode;
COMMIT;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid::regclass, count(*) FROM dbms_stats._column_stats_locked
 GROUP BY starelid
 ORDER BY starelid;

/*
 * No.14-5 dbms_stats.unlock_column_stats(regclass, attname)
 */
-- No.14-5-1
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT * FROM dbms_stats.backup_history
 ORDER BY id;
SELECT count(*) FROM dbms_stats.relation_stats_backup;
SELECT count(*) FROM dbms_stats.column_stats_backup;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT dbms_stats.unlock_column_stats('s0.st0', 'id');
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT * FROM dbms_stats.backup_history
 ORDER BY id;
SELECT count(*) FROM dbms_stats.relation_stats_backup;
SELECT count(*) FROM dbms_stats.column_stats_backup;

-- No.14-5-2
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
DELETE FROM dbms_stats._column_stats_locked;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT dbms_stats.unlock_column_stats('s0.st0', 'id');
SELECT count(*) FROM dbms_stats.column_stats_locked;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;

-- No.14-5-3
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT dbms_stats.unlock_column_stats('s0.st0', 'id');
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;

-- No.14-5-4
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT dbms_stats.unlock_column_stats('st0', 'id');
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;

-- No.14-5-5
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT dbms_stats.unlock_column_stats('s0.st0', 'dummy');
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;

-- No.14-5-6
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT dbms_stats.unlock_column_stats('s00.s0', 'id');
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;

-- No.14-5-7
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT dbms_stats.unlock_column_stats(NULL, 'id');
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;

-- No.14-5-8
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT dbms_stats.unlock_column_stats('s0.st0', NULL);
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;

-- No.14-5-9
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid, attname, stainherit FROM columns_locked_v c;
BEGIN;
SELECT relation::regclass, mode
 FROM pg_locks l join pg_class c on (l.relation = c.oid and c.relkind = 'r')
 WHERE mode LIKE '%ExclusiveLock%'
 ORDER BY relation::regclass::text, mode;
SELECT dbms_stats.unlock_column_stats('s0.st0', 'id');
SELECT relation::regclass, mode
 FROM pg_locks l join pg_class c on (l.relation = c.oid and c.relkind = 'r')
 WHERE mode LIKE '%ExclusiveLock%'
 ORDER BY relation::regclass::text, mode;
COMMIT;
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;

/*
 * No.14-6 dbms_stats.unlock_column_stats(schemaname, tablename, attname)
 */
-- No.14-6-1
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT * FROM dbms_stats.backup_history
 ORDER BY id;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT dbms_stats.unlock_column_stats('s0', 'st0', 'id');
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT * FROM dbms_stats.backup_history
 ORDER BY id;
SELECT count(*) FROM dbms_stats.relation_stats_backup;
SELECT count(*) FROM dbms_stats.column_stats_backup;

-- No.14-6-2
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
DELETE FROM dbms_stats._column_stats_locked;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT dbms_stats.unlock_column_stats('s0', 'st0', 'id');
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;

-- No.14-6-3
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT dbms_stats.unlock_column_stats('s0', 'st0', 'id');
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;

-- No.14-6-4
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT dbms_stats.unlock_column_stats('s0', 'st0', 'dummy');
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;

-- No.14-6-5
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT dbms_stats.unlock_column_stats(NULL, 'st0', 'id');
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;

-- No.14-6-6
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT dbms_stats.unlock_column_stats('s0', NULL, 'id');
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;

-- No.14-6-7
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT dbms_stats.unlock_column_stats('s0', 'st0', NULL);
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;

-- No.14-6-8
DELETE FROM dbms_stats._relation_stats_locked;
SELECT dbms_stats.lock_database_stats();
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
SELECT starelid, attname, stainherit FROM columns_locked_v c;
BEGIN;
SELECT relation::regclass, mode
 FROM pg_locks l join pg_class c on (l.relation = c.oid and c.relkind = 'r')
 WHERE mode LIKE '%ExclusiveLock%'
 ORDER BY relation::regclass::text, mode;
SELECT dbms_stats.unlock_column_stats('s0', 'st0', 'id');
SELECT relation::regclass, mode
 FROM pg_locks l join pg_class c on (l.relation = c.oid and c.relkind = 'r')
 WHERE mode LIKE '%ExclusiveLock%'
 ORDER BY relation::regclass::text, mode;
COMMIT;
SELECT starelid, attname, stainherit FROM columns_locked_v c;
SELECT relid::regclass FROM dbms_stats._relation_stats_locked
 GROUP BY relid
 ORDER BY relid;
