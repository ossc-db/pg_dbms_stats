CREATE VIEW plain_relations_statistic_v AS
SELECT oid::regclass,
       relpages,
       reltuples,
       relallvisible,
       pg_relation_size(oid) / 8192 curpages
  FROM pg_class
 ORDER BY oid::regclass::text;
CREATE VIEW relations_locked_v AS
SELECT relid::regclass,
       relname,
       relpages,
       reltuples,
       relallvisible,
       curpages
  FROM dbms_stats.relation_stats_locked
 ORDER BY relid;
CREATE VIEW relations_backup_v AS
SELECT id,
       relid::regclass,
       relname,
       relpages,
       reltuples,
       relallvisible,
       curpages
  FROM dbms_stats.relation_stats_backup
 ORDER BY id, relid;
CREATE VIEW plain_columns_statistic_v AS
SELECT starelid::regclass, staattnum, stainherit,
       stanullfrac, stawidth, stadistinct,
       stakind1, stakind2, stakind3, stakind4, stakind5,
       staop1, staop2, staop3, staop4, staop5,
       stanumbers1, stanumbers2, stanumbers3, stanumbers4, stanumbers5,
       stavalues1::text, stavalues2::text, stavalues3::text, stavalues4::text, stavalues5::text
  FROM pg_statistic
 ORDER BY starelid, staattnum, stainherit;
CREATE VIEW columns_locked_v AS
SELECT starelid::regclass, staattnum, attname, stainherit,
       stanullfrac, stawidth, stadistinct,
       stakind1, stakind2, stakind3, stakind4, stakind5,
       staop1, staop2, staop3, staop4, staop5,
       stanumbers1, stanumbers2, stanumbers3, stanumbers4, stanumbers5,
       stavalues1, stavalues2, stavalues3, stavalues4, stavalues5
  FROM dbms_stats.column_stats_locked c
  JOIN pg_attribute a
    ON (c.starelid = a.attrelid AND c.staattnum = a.attnum)
 ORDER BY starelid, staattnum, stainherit;
CREATE VIEW columns_backup_v AS
SELECT id, statypid,
       starelid::regclass, staattnum, stainherit,
       stanullfrac, stawidth, stadistinct,
       stakind1, stakind2, stakind3, stakind4, stakind5,
       staop1, staop2, staop3, staop4, staop5,
       stanumbers1, stanumbers2, stanumbers3, stanumbers4, stanumbers5,
       stavalues1, stavalues2, stavalues3, stavalues4, stavalues5
  FROM dbms_stats.column_stats_backup
 ORDER BY id, starelid, staattnum, stainherit;
CREATE TABLE dbms_stats.work (
  nspname          name   NOT NULL,
  relname          name   NOT NULL,
  relpages         int4   NOT NULL,
  reltuples        float4 NOT NULL,
  relallvisible    int4   NOT NULL,
  curpages         int4   NOT NULL,
  last_analyze     timestamp with time zone,
  last_autoanalyze timestamp with time zone,
  attname          name,
  nspname_of_typename name,
  typname          name,
  atttypmod        int4,
  stainherit       bool,
  stanullfrac      float4,
  stawidth         int4,
  stadistinct      float4,
  stakind1         int2,
  stakind2         int2,
  stakind3         int2,
  stakind4         int2,
  stakind5         int2,
  staop1           oid,
  staop2           oid,
  staop3           oid,
  staop4           oid,
  staop5           oid,
  stanumbers1      float4[],
  stanumbers2      float4[],
  stanumbers3      float4[],
  stanumbers4      float4[],
  stanumbers5      float4[],
  stavalues1       dbms_stats.anyarray,
  stavalues2       dbms_stats.anyarray,
  stavalues3       dbms_stats.anyarray,
  stavalues4       dbms_stats.anyarray
 ,stavalues5       dbms_stats.anyarray
);
CREATE VIEW work_v AS
SELECT nspname, relname, relpages, reltuples, relallvisible,
       curpages, attname, nspname_of_typename, typname, atttypmod,
       stainherit, stanullfrac, stawidth, stadistinct,
       stakind1, stakind2, stakind3, stakind4, stakind5,
       staop1, staop2, staop3, staop4, staop5,
       stanumbers1, stanumbers2, stanumbers3, stanumbers4, stanumbers5,
       stavalues1, stavalues2, stavalues3, stavalues4, stavalues5
  FROM dbms_stats.work
 ORDER BY nspname, relname, attname, stainherit;
ANALYZE s0.sft0;
