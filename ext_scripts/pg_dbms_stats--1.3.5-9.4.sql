/* pg_dbms_stats/pg_dbms_stats--1.3.5.sql */

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION pg_dbms_stats" to load this file. \quit

-- define alias of anyarray type because parser does not allow to use
-- anyarray in type definitions.
--
CREATE FUNCTION dbms_stats.anyarray_in(cstring) RETURNS dbms_stats.anyarray
    AS 'anyarray_in' LANGUAGE internal STRICT IMMUTABLE;
CREATE FUNCTION dbms_stats.anyarray_out(dbms_stats.anyarray) RETURNS cstring
    AS 'anyarray_out' LANGUAGE internal STRICT IMMUTABLE;
CREATE FUNCTION dbms_stats.anyarray_recv(internal) RETURNS dbms_stats.anyarray
    AS 'MODULE_PATHNAME', 'dbms_stats_array_recv' LANGUAGE C STRICT IMMUTABLE;
CREATE FUNCTION dbms_stats.anyarray_send(dbms_stats.anyarray) RETURNS bytea
    AS 'anyarray_send' LANGUAGE internal STRICT IMMUTABLE;
CREATE TYPE dbms_stats.anyarray (
    INPUT = dbms_stats.anyarray_in,
    OUTPUT = dbms_stats.anyarray_out,
    RECEIVE = dbms_stats.anyarray_recv,
    SEND = dbms_stats.anyarray_send,
    INTERNALLENGTH = VARIABLE,
    ALIGNMENT = double,
    STORAGE = extended,
    CATEGORY = 'P'
);

--
-- User defined stats tables
--

CREATE TABLE dbms_stats.relation_stats_locked (
    relid            oid    NOT NULL,
    relname          text   NOT NULL,
    relpages         int4,
    reltuples        float4,
    relallvisible    int4,
    curpages         int4,
    last_analyze     timestamp with time zone,
    last_autoanalyze timestamp with time zone,
    PRIMARY KEY (relid)
);

CREATE TABLE dbms_stats.column_stats_locked (
    starelid    oid    NOT NULL,
    staattnum   int2   NOT NULL,
    stainherit  bool   NOT NULL,
    stanullfrac float4,
    stawidth    int4,
    stadistinct float4,
    stakind1    int2,
    stakind2    int2,
    stakind3    int2,
    stakind4    int2,
    stakind5    int2,
    staop1      oid,
    staop2      oid,
    staop3      oid,
    staop4      oid,
    staop5      oid,
    stanumbers1 float4[],
    stanumbers2 float4[],
    stanumbers3 float4[],
    stanumbers4 float4[],
    stanumbers5 float4[],
    stavalues1  dbms_stats.anyarray,
    stavalues2  dbms_stats.anyarray,
    stavalues3  dbms_stats.anyarray,
    stavalues4  dbms_stats.anyarray,
    stavalues5  dbms_stats.anyarray,
    PRIMARY KEY (starelid, staattnum, stainherit),
    FOREIGN KEY (starelid) REFERENCES dbms_stats.relation_stats_locked (relid) ON DELETE CASCADE
);

--
-- Statistics backup tables
--

CREATE TABLE dbms_stats.backup_history (
    id      serial8 PRIMARY KEY,
    time    timestamp with time zone NOT NULL,
    unit    char(1) NOT NULL,
    comment text
);

CREATE TABLE dbms_stats.relation_stats_backup (
    id               int8   NOT NULL,
    relid            oid    NOT NULL,
    relname          text   NOT NULL,
    relpages         int4   NOT NULL,
    reltuples        float4 NOT NULL,
    relallvisible    int4   NOT NULL,
    curpages         int4   NOT NULL,
    last_analyze     timestamp with time zone,
    last_autoanalyze timestamp with time zone,
    PRIMARY KEY (id, relid),
    FOREIGN KEY (id) REFERENCES dbms_stats.backup_history (id) ON DELETE CASCADE
);

CREATE TABLE dbms_stats.column_stats_backup (
    id          int8   NOT NULL,
    statypid    oid    NOT NULL,
    starelid    oid    NOT NULL,
    staattnum   int2   NOT NULL,
    stainherit  bool   NOT NULL,
    stanullfrac float4 NOT NULL,
    stawidth    int4   NOT NULL,
    stadistinct float4 NOT NULL,
    stakind1    int2   NOT NULL,
    stakind2    int2   NOT NULL,
    stakind3    int2   NOT NULL,
    stakind4    int2   NOT NULL,
    stakind5    int2   NOT NULL,
    staop1      oid    NOT NULL,
    staop2      oid    NOT NULL,
    staop3      oid    NOT NULL,
    staop4      oid    NOT NULL,
    staop5      oid    NOT NULL,
    stanumbers1 float4[],
    stanumbers2 float4[],
    stanumbers3 float4[],
    stanumbers4 float4[],
    stanumbers5 float4[],
    stavalues1  dbms_stats.anyarray,
    stavalues2  dbms_stats.anyarray,
    stavalues3  dbms_stats.anyarray,
    stavalues4  dbms_stats.anyarray,
    stavalues5  dbms_stats.anyarray,
    PRIMARY KEY (id, starelid, staattnum, stainherit),
    FOREIGN KEY (id) REFERENCES dbms_stats.backup_history (id) ON DELETE CASCADE,
    FOREIGN KEY (id, starelid) REFERENCES dbms_stats.relation_stats_backup (id, relid) ON DELETE CASCADE
);

--
-- Functions
--

CREATE FUNCTION dbms_stats.relname(nspname text, relname text)
RETURNS text AS
$$SELECT quote_ident($1) || '.' || quote_ident($2)$$
LANGUAGE sql STABLE STRICT;

CREATE FUNCTION dbms_stats.is_system_schema(schemaname text)
RETURNS boolean AS
'MODULE_PATHNAME', 'dbms_stats_is_system_schema'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION dbms_stats.is_system_catalog(relid regclass)
RETURNS boolean AS
'MODULE_PATHNAME', 'dbms_stats_is_system_catalog'
LANGUAGE C STABLE;

CREATE FUNCTION dbms_stats.is_target_relkind(relkind "char")
RETURNS boolean AS
$$SELECT $1 IN ('r', 'i', 'f', 'm')$$
LANGUAGE sql STABLE;

CREATE FUNCTION dbms_stats.merge(
    lhs dbms_stats.column_stats_locked,
    rhs pg_catalog.pg_statistic
) RETURNS dbms_stats.column_stats_locked AS
'MODULE_PATHNAME', 'dbms_stats_merge'
LANGUAGE C STABLE;

CREATE VIEW dbms_stats.relation_stats_effective AS
    SELECT
        c.oid AS relid,
        dbms_stats.relname(nspname, c.relname) AS relname,
        COALESCE(v.relpages, c.relpages) AS relpages,
        COALESCE(v.reltuples, c.reltuples) AS reltuples,
        COALESCE(v.relallvisible, c.relallvisible) AS relallvisible,
        COALESCE(v.curpages,
            (pg_relation_size(c.oid) / current_setting('block_size')::int4)::int4)
            AS curpages,
        COALESCE(v.last_analyze,
            pg_catalog.pg_stat_get_last_analyze_time(c.oid))
            AS last_analyze,
        COALESCE(v.last_autoanalyze,
            pg_catalog.pg_stat_get_last_autoanalyze_time(c.oid))
            AS last_autoanalyze
      FROM pg_catalog.pg_class c
      JOIN pg_catalog.pg_namespace n
        ON c.relnamespace = n.oid
      LEFT JOIN dbms_stats.relation_stats_locked v
        ON v.relid = c.oid
     WHERE dbms_stats.is_target_relkind(c.relkind)
       AND NOT dbms_stats.is_system_schema(nspname);

CREATE VIEW dbms_stats.column_stats_effective AS
    SELECT * FROM (
        SELECT (dbms_stats.merge(v, s)).*
          FROM pg_catalog.pg_statistic s
          FULL JOIN dbms_stats.column_stats_locked v
         USING (starelid, staattnum, stainherit)
         WHERE NOT dbms_stats.is_system_catalog(starelid)
		   AND EXISTS (
			SELECT NULL
			  FROM pg_attribute a
			 WHERE a.attrelid = starelid
			   AND a.attnum = staattnum
			   AND a.attisdropped  = false
			)
        ) m
     WHERE starelid IS NOT NULL;

--
-- Note: This view is copied from pg_stats in
-- src/backend/catalog/system_views.sql in core source tree of version
-- 9.4, and customized for pg_dbms_stats.  Changes from orignal one are:
--   - rename from pg_stats to dbms_stats.stats by a view name.
--   - changed the table name from pg_statistic to dbms_stats.column_stats_effective.
--
CREATE VIEW dbms_stats.stats AS
    SELECT
        nspname AS schemaname,
        relname AS tablename,
        attname AS attname,
        stainherit AS inherited,
        stanullfrac AS null_frac,
        stawidth AS avg_width,
        stadistinct AS n_distinct,
        CASE
            WHEN stakind1 = 1 THEN stavalues1
            WHEN stakind2 = 1 THEN stavalues2
            WHEN stakind3 = 1 THEN stavalues3
            WHEN stakind4 = 1 THEN stavalues4
            WHEN stakind5 = 1 THEN stavalues5
        END AS most_common_vals,
        CASE
            WHEN stakind1 = 1 THEN stanumbers1
            WHEN stakind2 = 1 THEN stanumbers2
            WHEN stakind3 = 1 THEN stanumbers3
            WHEN stakind4 = 1 THEN stanumbers4
            WHEN stakind5 = 1 THEN stanumbers5
        END AS most_common_freqs,
        CASE
            WHEN stakind1 = 2 THEN stavalues1
            WHEN stakind2 = 2 THEN stavalues2
            WHEN stakind3 = 2 THEN stavalues3
            WHEN stakind4 = 2 THEN stavalues4
            WHEN stakind5 = 2 THEN stavalues5
        END AS histogram_bounds,
        CASE
            WHEN stakind1 = 3 THEN stanumbers1[1]
            WHEN stakind2 = 3 THEN stanumbers2[1]
            WHEN stakind3 = 3 THEN stanumbers3[1]
            WHEN stakind4 = 3 THEN stanumbers4[1]
            WHEN stakind5 = 3 THEN stanumbers5[1]
        END AS correlation,
        CASE
            WHEN stakind1 = 4 THEN stavalues1
            WHEN stakind2 = 4 THEN stavalues2
            WHEN stakind3 = 4 THEN stavalues3
            WHEN stakind4 = 4 THEN stavalues4
            WHEN stakind5 = 4 THEN stavalues5
        END AS most_common_elems,
        CASE
            WHEN stakind1 = 4 THEN stanumbers1
            WHEN stakind2 = 4 THEN stanumbers2
            WHEN stakind3 = 4 THEN stanumbers3
            WHEN stakind4 = 4 THEN stanumbers4
            WHEN stakind5 = 4 THEN stanumbers5
        END AS most_common_elem_freqs,
        CASE
            WHEN stakind1 = 5 THEN stanumbers1
            WHEN stakind2 = 5 THEN stanumbers2
            WHEN stakind3 = 5 THEN stanumbers3
            WHEN stakind4 = 5 THEN stanumbers4
            WHEN stakind5 = 5 THEN stanumbers5
        END AS elem_count_histogram
    FROM dbms_stats.column_stats_effective s JOIN pg_class c ON (c.oid = s.starelid)
         JOIN pg_attribute a ON (c.oid = attrelid AND attnum = s.staattnum)
         LEFT JOIN pg_namespace n ON (n.oid = c.relnamespace)
    WHERE NOT attisdropped AND has_column_privilege(c.oid, a.attnum, 'select');

--
-- Utility functions
--

CREATE FUNCTION dbms_stats.invalidate_relation_cache()
    RETURNS trigger AS
    'MODULE_PATHNAME', 'dbms_stats_invalidate_relation_cache'
    LANGUAGE C;

-- Invalidate cached plans when dbms_stats.relation_stats_locked is modified.
CREATE TRIGGER invalidate_relation_cache
    BEFORE INSERT OR DELETE OR UPDATE
    ON dbms_stats.relation_stats_locked
   FOR EACH ROW EXECUTE PROCEDURE dbms_stats.invalidate_relation_cache();

CREATE FUNCTION dbms_stats.invalidate_column_cache()
    RETURNS trigger AS
    'MODULE_PATHNAME', 'dbms_stats_invalidate_column_cache'
    LANGUAGE C;

-- Invalidate cached plans when dbms_stats.column_stats_locked is modified.
CREATE TRIGGER invalidate_column_cache
    BEFORE INSERT OR DELETE OR UPDATE
    ON dbms_stats.column_stats_locked
    FOR EACH ROW EXECUTE PROCEDURE dbms_stats.invalidate_column_cache();

--
-- BACKUP_STATS: Statistics backup functions
--

CREATE FUNCTION dbms_stats.backup(
    backup_id int8,
    relid regclass,
    attnum int2
) RETURNS int8 AS
$$
/* Lock the backup id */
SELECT * from dbms_stats.backup_history
    WHERE  id = $1 FOR UPDATE;

INSERT INTO dbms_stats.relation_stats_backup
    SELECT $1, v.relid, v.relname, v.relpages, v.reltuples, v.relallvisible,
           v.curpages, v.last_analyze, v.last_autoanalyze
      FROM pg_catalog.pg_class c,
           dbms_stats.relation_stats_effective v
     WHERE c.oid = v.relid
       AND dbms_stats.is_target_relkind(relkind)
       AND NOT dbms_stats.is_system_catalog(v.relid)
       AND (v.relid = $2 OR $2 IS NULL);

INSERT INTO dbms_stats.column_stats_backup
    SELECT $1, atttypid, s.*
      FROM pg_catalog.pg_class c,
           dbms_stats.column_stats_effective s,
           pg_catalog.pg_attribute a
     WHERE c.oid = starelid
       AND starelid = attrelid
       AND staattnum = attnum
       AND dbms_stats.is_target_relkind(relkind)
       AND NOT dbms_stats.is_system_catalog(c.oid)
       AND ($2 IS NULL OR starelid = $2)
       AND ($3 IS NULL OR staattnum = $3);

SELECT $1;
$$
LANGUAGE sql;

CREATE FUNCTION dbms_stats.backup(
    relid regclass DEFAULT NULL,
    attname text DEFAULT NULL,
    comment text DEFAULT NULL
) RETURNS int8 AS
$$
DECLARE
    backup_id       int8;
    backup_relkind  "char";
    set_attnum      int2;
    unit_type       char;
BEGIN
    IF $1 IS NULL AND $2 IS NOT NULL THEN
        RAISE EXCEPTION 'relation required';
    END IF;
    IF $1 IS NOT NULL THEN
        SELECT relkind INTO backup_relkind
          FROM pg_catalog.pg_class WHERE oid = $1 FOR SHARE;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'relation "%" not found', $1;
        END IF;
        IF NOT dbms_stats.is_target_relkind(backup_relkind) THEN
            RAISE EXCEPTION 'relation of relkind "%" cannot have statistics to backup: "%"',
				backup_relkind, $1
				USING HINT = 'Only tables(r), materialized views(m), foreign tables(f) and indexes(i) are allowed.';
        END IF;
        IF dbms_stats.is_system_catalog($1) THEN
            RAISE EXCEPTION 'backing up statistics is inhibited for system catalogs: "%"', $1;
        END IF;
        IF $2 IS NOT NULL THEN
            SELECT a.attnum INTO set_attnum FROM pg_catalog.pg_attribute a
             WHERE a.attrelid = $1 AND a.attname = $2 FOR SHARE;
            IF set_attnum IS NULL THEN
                RAISE EXCEPTION 'column "%" not found in relation "%"', $2, $1;
            END IF;
            IF NOT EXISTS(SELECT * FROM dbms_stats.column_stats_effective WHERE starelid = $1 AND staattnum = set_attnum) THEN
                RAISE EXCEPTION 'no statistics available for column "%" of relation "%"', $2, $1;
            END IF;
            unit_type = 'c';
        ELSE
            unit_type = 't';
        END IF;
    ELSE
        unit_type = 'd';
    END IF;

    INSERT INTO dbms_stats.backup_history(time, unit, comment)
        VALUES (current_timestamp, unit_type, $3)
        RETURNING dbms_stats.backup(id, $1, set_attnum) INTO backup_id;
    RETURN backup_id;
END;
$$
LANGUAGE plpgsql;

CREATE FUNCTION dbms_stats.backup_database_stats(
    comment text
) RETURNS int8 AS
$$
SELECT dbms_stats.backup(NULL, NULL, $1)
$$
LANGUAGE sql;

CREATE FUNCTION dbms_stats.backup_schema_stats(
    schemaname text,
    comment text
) RETURNS int8 AS
$$
DECLARE
    backup_id       int8;
BEGIN
    IF NOT EXISTS(SELECT * FROM pg_namespace WHERE nspname = $1 FOR SHARE)
    THEN
        RAISE EXCEPTION 'schema "%" not found', $1;
    END IF;
    IF dbms_stats.is_system_schema($1) THEN
        RAISE EXCEPTION 'backing up statistics is inhibited for system schemas: "%"', $1;
    END IF;

    INSERT INTO dbms_stats.backup_history(time, unit, comment)
        VALUES (current_timestamp, 's', comment)
        RETURNING id INTO backup_id;

    PERFORM dbms_stats.backup(backup_id, cn.oid, NULL)
      FROM (SELECT c.oid
              FROM pg_catalog.pg_class c,
                   pg_catalog.pg_namespace n
             WHERE n.nspname = schemaname
               AND c.relnamespace = n.oid
               AND dbms_stats.is_target_relkind(c.relkind)
             ORDER BY c.oid
           ) cn;

    RETURN backup_id;
END;
$$
LANGUAGE plpgsql;

CREATE FUNCTION dbms_stats.backup_table_stats(
    relid regclass,
    comment text
) RETURNS int8 AS
$$
SELECT dbms_stats.backup($1, NULL, $2)
$$
LANGUAGE sql;

CREATE FUNCTION dbms_stats.backup_table_stats(
    schemaname text,
    tablename text,
    comment text
) RETURNS int8 AS
$$
SELECT dbms_stats.backup(dbms_stats.relname($1, $2)::regclass, NULL, $3)
$$
LANGUAGE sql;

CREATE FUNCTION dbms_stats.backup_column_stats(
    relid regclass,
    attname text,
    comment text
) RETURNS int8 AS
$$
SELECT dbms_stats.backup($1, $2, $3)
$$
LANGUAGE sql;

CREATE FUNCTION dbms_stats.backup_column_stats(
    schemaname text,
    tablename text,
    attname text,
    comment text
) RETURNS int8 AS
$$
SELECT dbms_stats.backup(dbms_stats.relname($1, $2)::regclass, $3, $4)
$$
LANGUAGE sql;

--
-- RESTORE_STATS: Statistics restore functions
--
CREATE FUNCTION dbms_stats.restore(
    backup_id int8,
    relid regclass DEFAULT NULL,
    attname text DEFAULT NULL
) RETURNS SETOF regclass AS
$$
DECLARE
    restore_id      int8;
    restore_relid   regclass;
    restore_attnum  int2;
    set_attnum      int2;
    restore_attname text;
    restore_type    regtype;
    cur_type        regtype;
BEGIN
    IF $1 IS NULL THEN
        RAISE EXCEPTION 'backup id required';
    END IF;
    IF $2 IS NULL AND $3 IS NOT NULL THEN
        RAISE EXCEPTION 'relation required';
    END IF;
    IF NOT EXISTS(SELECT * FROM dbms_stats.backup_history
                           WHERE id <= $1 FOR SHARE) THEN
        RAISE EXCEPTION 'backup id % not found', $1;
    END IF;
    IF $2 IS NOT NULL THEN
        IF NOT EXISTS(SELECT * FROM pg_catalog.pg_class
                               WHERE oid = $2 FOR SHARE) THEN
            RAISE EXCEPTION 'relation "%" not found', $2;
        END IF;
		-- Grabbing all backups for the relation which is not used in restore.
        IF NOT EXISTS(SELECT * FROM dbms_stats.relation_stats_backup b
                       WHERE b.id <= $1 AND b.relid = $2 FOR SHARE) THEN
            RAISE EXCEPTION 'statistics of relation "%" not found in any backups before backup id = %', $2, $1;
        END IF;
        IF $3 IS NOT NULL THEN
            SELECT a.attnum INTO set_attnum FROM pg_catalog.pg_attribute a
             WHERE a.attrelid = $2 AND a.attname = $3;
            IF set_attnum IS NULL THEN
				RAISE EXCEPTION 'column "%" not found in relation %', $3, $2;
            END IF;
            IF NOT EXISTS(SELECT * FROM dbms_stats.column_stats_backup WHERE id <= $1 AND starelid = $2 AND staattnum = set_attnum) THEN
                RAISE EXCEPTION 'statistics of column "%" of relation "%" are not found in any backups before',$3, $2, $1;
            END IF;
        END IF;
		PERFORM * FROM dbms_stats.relation_stats_locked r
                  WHERE r.relid = $2 FOR UPDATE;
    ELSE
		/* Lock the whole relation stats if relation is not specified.*/
	    LOCK dbms_stats.relation_stats_locked IN EXCLUSIVE MODE;
    END IF;

    FOR restore_id, restore_relid IN
	  SELECT max(id), coid FROM
        (SELECT b.id as id, c.oid as coid
           FROM pg_class c, dbms_stats.relation_stats_backup b
          WHERE (c.oid = $2 OR $2 IS NULL)
            AND c.oid = b.relid
            AND dbms_stats.is_target_relkind(c.relkind)
            AND NOT dbms_stats.is_system_catalog(c.oid)
            AND b.id <= $1
         FOR SHARE) t
      GROUP BY coid
      ORDER BY coid::regclass::text
    LOOP
        UPDATE dbms_stats.relation_stats_locked r
           SET relid = b.relid,
               relname = b.relname,
               relpages = b.relpages,
               reltuples = b.reltuples,
               relallvisible = b.relallvisible,
               curpages = b.curpages,
               last_analyze = b.last_analyze,
               last_autoanalyze = b.last_autoanalyze
          FROM dbms_stats.relation_stats_backup b
         WHERE r.relid = restore_relid
           AND b.id = restore_id
           AND b.relid = restore_relid;
        IF NOT FOUND THEN
            INSERT INTO dbms_stats.relation_stats_locked
            SELECT b.relid,
                   b.relname,
                   b.relpages,
                   b.reltuples,
                   b.relallvisible,
                   b.curpages,
                   b.last_analyze,
                   b.last_autoanalyze
              FROM dbms_stats.relation_stats_backup b
             WHERE b.id = restore_id
               AND b.relid = restore_relid;
        END IF;
        RETURN NEXT restore_relid;
    END LOOP;

    FOR restore_id, restore_relid, restore_attnum, restore_type, cur_type IN
        SELECT t.id, t.oid, t.attnum, b.statypid, a.atttypid
          FROM pg_attribute a,
               dbms_stats.column_stats_backup b,
               (SELECT max(b.id) AS id, c.oid, a.attnum
                  FROM pg_class c, pg_attribute a, dbms_stats.column_stats_backup b
                 WHERE (c.oid = $2 OR $2 IS NULL)
                   AND c.oid = a.attrelid
                   AND c.oid = b.starelid
                   AND (a.attnum = set_attnum OR set_attnum IS NULL)
                   AND a.attnum = b.staattnum
                   AND NOT a.attisdropped
                   AND dbms_stats.is_target_relkind(c.relkind)
                   AND b.id <= $1
                 GROUP BY c.oid, a.attnum) t
         WHERE a.attrelid = t.oid
           AND a.attnum = t.attnum
           AND b.id = t.id
           AND b.starelid = t.oid
           AND b.staattnum = t.attnum
    LOOP
        IF restore_type <> cur_type THEN
            SELECT a.attname INTO restore_attname
              FROM pg_catalog.pg_attribute a
             WHERE a.attrelid = restore_relid
               AND a.attnum = restore_attnum;
            RAISE WARNING 'data type of column "%.%" is inconsistent between database(%) and backup (%). Skip.',
                restore_relid, restore_attname, cur_type, restore_type;
        ELSE
            DELETE FROM dbms_stats.column_stats_locked
             WHERE starelid = restore_relid
               AND staattnum = restore_attnum;
            INSERT INTO dbms_stats.column_stats_locked
                SELECT starelid, staattnum, stainherit,
                       stanullfrac, stawidth, stadistinct,
                       stakind1, stakind2, stakind3, stakind4, stakind5,
                       staop1, staop2, staop3, staop4, staop5,
                       stanumbers1, stanumbers2, stanumbers3, stanumbers4, stanumbers5,
                       stavalues1, stavalues2, stavalues3, stavalues4, stavalues5
                  FROM dbms_stats.column_stats_backup
                 WHERE id = restore_id
                   AND starelid = restore_relid
                   AND staattnum = restore_attnum;
        END IF;
    END LOOP;
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'This operation is canceled by simultaneous lock or restore operation on the same relation.';
END;
$$
LANGUAGE plpgsql;

CREATE FUNCTION dbms_stats.restore_database_stats(
    as_of_timestamp timestamp with time zone
) RETURNS SETOF regclass AS
$$
SELECT dbms_stats.restore(m.id, m.relid)
  FROM (SELECT max(id) AS id, relid
        FROM (SELECT r.id, r.relid
              FROM pg_class c, dbms_stats.relation_stats_backup r,
                   dbms_stats.backup_history b
              WHERE c.oid = r.relid
                AND r.id = b.id
                AND b.time <= $1
              FOR SHARE) t1
        GROUP BY t1.relid
        ORDER BY t1.relid) m;
$$
LANGUAGE sql STRICT;

CREATE FUNCTION dbms_stats.restore_schema_stats(
    schemaname text,
    as_of_timestamp timestamp with time zone
) RETURNS SETOF regclass AS
$$
BEGIN
    IF NOT EXISTS(SELECT * FROM pg_namespace WHERE nspname = $1) THEN
        RAISE EXCEPTION 'schema "%" not found', $1;
    END IF;
    IF dbms_stats.is_system_schema($1) THEN
        RAISE EXCEPTION 'restoring statistics is inhibited for system schemas: "%"', $1;
    END IF;

    RETURN QUERY
        SELECT dbms_stats.restore(m.id, m.relid)
          FROM (SELECT max(id) AS id, relid
                FROM (SELECT r.id, r.relid
                      FROM pg_class c, pg_namespace n,
                           dbms_stats.relation_stats_backup r,
                           dbms_stats.backup_history b
                      WHERE c.oid = r.relid
                        AND c.relnamespace = n.oid
                        AND n.nspname = $1
                        AND r.id = b.id
                        AND b.time <= $2
    					FOR SHARE) t1
                GROUP BY t1.relid
                ORDER BY t1.relid) m;
END;
$$
LANGUAGE plpgsql STRICT;

CREATE FUNCTION dbms_stats.restore_table_stats(
    relid regclass,
    as_of_timestamp timestamp with time zone
) RETURNS SETOF regclass AS
$$
SELECT dbms_stats.restore(max(id), $1, NULL)
  FROM dbms_stats.backup_history WHERE time <= $2
$$
LANGUAGE sql STRICT;

CREATE FUNCTION dbms_stats.restore_table_stats(
    schemaname text,
    tablename text,
    as_of_timestamp timestamp with time zone
) RETURNS SETOF regclass AS
$$
SELECT dbms_stats.restore_table_stats(dbms_stats.relname($1, $2)::regclass, $3)
$$
LANGUAGE sql STRICT;

CREATE FUNCTION dbms_stats.restore_column_stats(
    relid regclass,
    attname text,
    as_of_timestamp timestamp with time zone
) RETURNS SETOF regclass AS
$$
SELECT dbms_stats.restore(max(id), $1, $2)
  FROM dbms_stats.backup_history WHERE time <= $3
$$
LANGUAGE sql STRICT;

CREATE FUNCTION dbms_stats.restore_column_stats(
    schemaname text,
    tablename text,
    attname text,
    as_of_timestamp timestamp with time zone
) RETURNS SETOF regclass AS
$$
SELECT dbms_stats.restore(max(id), dbms_stats.relname($1, $2)::regclass, $3)
  FROM dbms_stats.backup_history WHERE time <= $4
$$
LANGUAGE sql STRICT;

CREATE FUNCTION dbms_stats.restore_stats(
    backup_id int8
) RETURNS SETOF regclass AS
$$
DECLARE
    restore_relid   regclass;
    restore_attnum  int2;
    restore_attname text;
    restore_type    regtype;
    cur_type        regtype;
BEGIN
    IF NOT EXISTS(SELECT * FROM dbms_stats.backup_history WHERE id = $1) THEN
        RAISE EXCEPTION 'backup id % not found', $1;
    END IF;

    /* Lock the backup */
    PERFORM * from dbms_stats.relation_stats_backup b
        WHERE  id = $1 FOR SHARE;

	/* Locking only relation_stats_locked is sufficient */
    LOCK dbms_stats.relation_stats_locked IN EXCLUSIVE MODE;

    FOR restore_relid IN
        SELECT b.relid
          FROM pg_class c
          JOIN dbms_stats.relation_stats_backup b ON (c.oid = b.relid)
         WHERE b.id = $1
         ORDER BY c.oid::regclass::text
    LOOP
        UPDATE dbms_stats.relation_stats_locked r
           SET relid = b.relid,
               relname = b.relname,
               relpages = b.relpages,
               reltuples = b.reltuples,
               relallvisible = b.relallvisible,
               curpages = b.curpages,
               last_analyze = b.last_analyze,
               last_autoanalyze = b.last_autoanalyze
          FROM dbms_stats.relation_stats_backup b
         WHERE r.relid = restore_relid
           AND b.id = $1
           AND b.relid = restore_relid;
        IF NOT FOUND THEN
            INSERT INTO dbms_stats.relation_stats_locked
            SELECT b.relid,
                   b.relname,
                   b.relpages,
                   b.reltuples,
                   b.relallvisible,
                   b.curpages,
                   b.last_analyze,
                   b.last_autoanalyze
              FROM dbms_stats.relation_stats_backup b
             WHERE b.id = $1
               AND b.relid = restore_relid;
        END IF;
        RETURN NEXT restore_relid;
    END LOOP;

    FOR restore_relid, restore_attnum, restore_type, cur_type  IN
        SELECT c.oid, a.attnum, b.statypid, a.atttypid
          FROM pg_class c
          JOIN dbms_stats.column_stats_backup b ON (c.oid = b.starelid)
          JOIN pg_attribute a ON (b.starelid = attrelid
                              AND b.staattnum = a.attnum)
         WHERE b.id = $1
    LOOP
        IF restore_type <> cur_type THEN
            SELECT attname INTO restore_attname
              FROM pg_catalog.pg_attribute
             WHERE attrelid = restore_relid
               AND attnum = restore_attnum;
            RAISE WARNING 'data type of column "%.%" is inconsistent between database(%) and backup (%). Skip.',
                restore_relid, restore_attname, cur_type, restore_type;
        ELSE
            DELETE FROM dbms_stats.column_stats_locked
             WHERE starelid = restore_relid
               AND staattnum = restore_attnum;
            INSERT INTO dbms_stats.column_stats_locked
                SELECT starelid, staattnum, stainherit,
                       stanullfrac, stawidth, stadistinct,
                       stakind1, stakind2, stakind3, stakind4, stakind5,
                       staop1, staop2, staop3, staop4, staop5,
                       stanumbers1, stanumbers2, stanumbers3, stanumbers4, stanumbers5,
                       stavalues1, stavalues2, stavalues3, stavalues4, stavalues5
                  FROM dbms_stats.column_stats_backup
                 WHERE id = $1
                   AND starelid = restore_relid
                   AND staattnum = restore_attnum;
        END IF;
    END LOOP;

END;
$$
LANGUAGE plpgsql STRICT;

--
-- LOCK_STATS: Statistics lock functions
--

CREATE FUNCTION dbms_stats.lock(
    relid regclass,
    attname text
) RETURNS regclass AS
$$
DECLARE
    lock_relkind "char";
    set_attnum   int2;
    r            record;
BEGIN
    IF $1 IS NULL THEN
        RAISE EXCEPTION 'relation required';
    END IF;
    IF $2 IS NULL THEN
        RETURN dbms_stats.lock($1);
    END IF;
    SELECT relkind INTO lock_relkind FROM pg_catalog.pg_class WHERE oid = $1;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'relation "%" not found', $1;
    END IF;
    IF NOT dbms_stats.is_target_relkind(lock_relkind) THEN
        RAISE EXCEPTION '"%" must be a table or an index', $1;
    END IF;
    IF EXISTS(SELECT * FROM pg_catalog.pg_index WHERE lock_relkind = 'i' AND indexrelid = $1 AND indexprs IS NULL) THEN
        RAISE EXCEPTION '"%" must be an expression index', $1;
    END IF;
    IF dbms_stats.is_system_catalog($1) THEN
		RAISE EXCEPTION 'locking statistics is inhibited for system catalogs: "%"', $1;
    END IF;
    SELECT a.attnum INTO set_attnum FROM pg_catalog.pg_attribute a
     WHERE a.attrelid = $1 AND a.attname = $2;
    IF set_attnum IS NULL THEN
        RAISE EXCEPTION 'column "%" not found in relation "%"', $2, $1;
    END IF;

	/*
	 * If we don't have per-table statistics, create new one which has NULL for
	 * every statistic value for column_stats_effective.
	 */
    IF NOT EXISTS(SELECT * FROM dbms_stats.relation_stats_locked ru
                   WHERE ru.relid = $1 FOR SHARE) THEN
        INSERT INTO dbms_stats.relation_stats_locked
            SELECT $1, dbms_stats.relname(nspname, relname),
                   NULL, NULL, NULL, NULL, NULL
              FROM pg_catalog.pg_class c, pg_catalog.pg_namespace n
             WHERE c.relnamespace = n.oid
               AND c.oid = $1;
    END IF;

	/*
	 * Process for per-column statistics
	 */
    FOR r IN
        SELECT stainherit, stanullfrac, stawidth, stadistinct,
               stakind1, stakind2, stakind3, stakind4, stakind5,
               staop1, staop2, staop3, staop4, staop5,
               stanumbers1, stanumbers2, stanumbers3, stanumbers4, stanumbers5,
               stavalues1, stavalues2, stavalues3, stavalues4, stavalues5
          FROM dbms_stats.column_stats_effective
         WHERE starelid = $1
           AND staattnum = set_attnum
    LOOP
        UPDATE dbms_stats.column_stats_locked c
           SET stanullfrac = r.stanullfrac,
               stawidth = r.stawidth,
               stadistinct = r.stadistinct,
               stakind1 = r.stakind1,
               stakind2 = r.stakind2,
               stakind3 = r.stakind3,
               stakind4 = r.stakind4,
               stakind5 = r.stakind5,
               staop1 = r.staop1,
               staop2 = r.staop2,
               staop3 = r.staop3,
               staop4 = r.staop4,
               staop5 = r.staop5,
               stanumbers1 = r.stanumbers1,
               stanumbers2 = r.stanumbers2,
               stanumbers3 = r.stanumbers3,
               stanumbers4 = r.stanumbers4,
               stanumbers5 = r.stanumbers5,
               stavalues1 = r.stavalues1,
               stavalues2 = r.stavalues2,
               stavalues3 = r.stavalues3,
               stavalues4 = r.stavalues4,
               stavalues5 = r.stavalues5
         WHERE c.starelid = $1
           AND c.staattnum = set_attnum
           AND c.stainherit = r.stainherit;

        IF NOT FOUND THEN
            INSERT INTO dbms_stats.column_stats_locked
                 VALUES ($1,
                         set_attnum,
                         r.stainherit,
                         r.stanullfrac,
                         r.stawidth,
                         r.stadistinct,
                         r.stakind1,
                         r.stakind2,
                         r.stakind3,
                         r.stakind4,
                         r.stakind5,
                         r.staop1,
                         r.staop2,
                         r.staop3,
                         r.staop4,
                         r.staop5,
                         r.stanumbers1,
                         r.stanumbers2,
                         r.stanumbers3,
                         r.stanumbers4,
                         r.stanumbers5,
                         r.stavalues1,
                         r.stavalues2,
                         r.stavalues3,
                         r.stavalues4,
                         r.stavalues5);
        END IF;
        END LOOP;

		/* If we don't have statistics at all, raise error. */
        IF NOT FOUND THEN
			RAISE EXCEPTION 'no statistics available for column "%" of relation "%"', $2, $1::regclass;
		END IF;

    RETURN $1;
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'This operation is canceled by simultaneous lock or restore operation on the same relation.';
END;
$$
LANGUAGE plpgsql;

CREATE FUNCTION dbms_stats.lock(relid regclass)
    RETURNS regclass AS
$$
DECLARE
    lock_relkind "char";
    i            record;
BEGIN
    IF $1 IS NULL THEN
        RAISE EXCEPTION 'relation required';
    END IF;
    SELECT relkind INTO lock_relkind FROM pg_catalog.pg_class WHERE oid = $1;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'relation "%" not found', $1;
    END IF;
    IF NOT dbms_stats.is_target_relkind(lock_relkind) THEN
        RAISE EXCEPTION 'locking statistics is not allowed for relations with relkind "%": "%"', lock_relkind, $1
			USING HINT = 'Only tables(r, m, f) and indexes(i) are lockable.';
    END IF;
    IF dbms_stats.is_system_catalog($1) THEN
		RAISE EXCEPTION 'locking statistics is not allowed for system catalogs: "%"', $1;
    END IF;

    UPDATE dbms_stats.relation_stats_locked r
       SET relname = dbms_stats.relname(nspname, c.relname),
           relpages = v.relpages,
           reltuples = v.reltuples,
           relallvisible = v.relallvisible,
           curpages = v.curpages,
           last_analyze = v.last_analyze,
           last_autoanalyze = v.last_autoanalyze
      FROM pg_catalog.pg_class c,
           pg_catalog.pg_namespace n,
           dbms_stats.relation_stats_effective v
     WHERE r.relid = $1
       AND c.oid = $1
       AND c.relnamespace = n.oid
       AND v.relid = $1;
    IF NOT FOUND THEN
        INSERT INTO dbms_stats.relation_stats_locked
        SELECT $1, dbms_stats.relname(nspname, c.relname),
               v.relpages, v.reltuples, v.relallvisible, v.curpages,
               v.last_analyze, v.last_autoanalyze
          FROM pg_catalog.pg_class c,
               pg_catalog.pg_namespace n,
               dbms_stats.relation_stats_effective v
         WHERE c.oid = $1
           AND c.relnamespace = n.oid
           AND v.relid = $1;
    END IF;

    IF EXISTS(SELECT *
                FROM pg_catalog.pg_class c LEFT JOIN pg_catalog.pg_index ind
                  ON c.oid = ind.indexrelid
               WHERE c.oid = $1
                 AND c.relkind = 'i'
                 AND ind.indexprs IS NULL) THEN
        RETURN $1;
    END IF;

    FOR i IN
        SELECT staattnum, stainherit, stanullfrac,
               stawidth, stadistinct,
               stakind1, stakind2, stakind3, stakind4, stakind5,
               staop1, staop2, staop3, staop4, staop5,
               stanumbers1, stanumbers2, stanumbers3, stanumbers4, stanumbers5,
               stavalues1, stavalues2, stavalues3, stavalues4, stavalues5
          FROM dbms_stats.column_stats_effective
         WHERE starelid = $1
    LOOP
        UPDATE dbms_stats.column_stats_locked c
           SET stanullfrac = i.stanullfrac,
               stawidth = i.stawidth,
               stadistinct = i.stadistinct,
               stakind1 = i.stakind1,
               stakind2 = i.stakind2,
               stakind3 = i.stakind3,
               stakind4 = i.stakind4,
               stakind5 = i.stakind5,
               staop1 = i.staop1,
               staop2 = i.staop2,
               staop3 = i.staop3,
               staop4 = i.staop4,
               staop5 = i.staop5,
               stanumbers1 = i.stanumbers1,
               stanumbers2 = i.stanumbers2,
               stanumbers3 = i.stanumbers3,
               stanumbers4 = i.stanumbers4,
               stanumbers5 = i.stanumbers5,
               stavalues1 = i.stavalues1,
               stavalues2 = i.stavalues2,
               stavalues3 = i.stavalues3,
               stavalues4 = i.stavalues4,
               stavalues5 = i.stavalues5
         WHERE c.starelid = $1
           AND c.staattnum = i.staattnum
           AND c.stainherit = i.stainherit;

        IF NOT FOUND THEN
            INSERT INTO dbms_stats.column_stats_locked
                 VALUES ($1,
                         i.staattnum,
                         i.stainherit,
                         i.stanullfrac,
                         i.stawidth,
                         i.stadistinct,
                         i.stakind1,
                         i.stakind2,
                         i.stakind3,
                         i.stakind4,
                         i.stakind5,
                         i.staop1,
                         i.staop2,
                         i.staop3,
                         i.staop4,
                         i.staop5,
                         i.stanumbers1,
                         i.stanumbers2,
                         i.stanumbers3,
                         i.stanumbers4,
                         i.stanumbers5,
                         i.stavalues1,
                         i.stavalues2,
                         i.stavalues3,
                         i.stavalues4,
                         i.stavalues5);
            END IF;
        END LOOP;

    RETURN $1;
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'This operation is canceled by simultaneous lock operation on the same relation.';
END;
$$
LANGUAGE plpgsql;

CREATE FUNCTION dbms_stats.lock_database_stats()
  RETURNS SETOF regclass AS
$$
SELECT dbms_stats.lock(c.oid)
  FROM (SELECT oid
          FROM pg_catalog.pg_class
         WHERE NOT dbms_stats.is_system_catalog(oid)
           AND dbms_stats.is_target_relkind(relkind)
         ORDER BY pg_class.oid
       ) c;
$$
LANGUAGE sql;

CREATE FUNCTION dbms_stats.lock_schema_stats(
    schemaname text
) RETURNS SETOF regclass AS
$$
BEGIN
    IF NOT EXISTS(SELECT * FROM pg_namespace WHERE nspname = $1) THEN
        RAISE EXCEPTION 'schema "%" not found', $1;
    END IF;
    IF dbms_stats.is_system_schema($1) THEN
        RAISE EXCEPTION 'locking statistics is not allowed for system schemas: "%"', $1;
    END IF;

    RETURN QUERY
        SELECT dbms_stats.lock(cn.oid)
          FROM (SELECT c.oid
                  FROM pg_class c, pg_namespace n
                 WHERE c.relnamespace = n.oid
                   AND dbms_stats.is_target_relkind(c.relkind)
                   AND n.nspname = $1
                 ORDER BY c.oid
               ) cn;
END;
$$
LANGUAGE plpgsql STRICT;

CREATE FUNCTION dbms_stats.lock_table_stats(relid regclass)
  RETURNS regclass AS
$$
SELECT dbms_stats.lock($1)
$$
LANGUAGE sql STRICT;

CREATE FUNCTION dbms_stats.lock_table_stats(
    schemaname text,
    tablename text
) RETURNS regclass AS
$$
SELECT dbms_stats.lock(dbms_stats.relname($1, $2)::regclass)
$$
LANGUAGE sql STRICT;

CREATE FUNCTION dbms_stats.lock_column_stats(
    relid regclass,
    attname text
) RETURNS regclass AS
$$
SELECT dbms_stats.lock($1, $2)
$$
LANGUAGE sql STRICT;

CREATE FUNCTION dbms_stats.lock_column_stats(
    schemaname text,
    tablename text,
    attname text
) RETURNS regclass AS
$$
SELECT dbms_stats.lock(dbms_stats.relname($1, $2)::regclass, $3)
$$
LANGUAGE sql STRICT;

--
-- UNLOCK_STATS: Statistics unlock functions
--

CREATE FUNCTION dbms_stats.unlock(
    relid regclass DEFAULT NULL,
    attname text DEFAULT NULL
) RETURNS SETOF regclass AS
$$
DECLARE
    set_attnum int2;
    unlock_id  int8;
BEGIN
    IF $1 IS NULL AND $2 IS NOT NULL THEN
        RAISE EXCEPTION 'relation required';
    END IF;

	/*
	 * Lock the target relation to prevent conflicting with stats lock/restore
     */
	PERFORM * FROM dbms_stats.relation_stats_locked ru
         WHERE (ru.relid = $1 OR $1 IS NULL) FOR UPDATE;

    SELECT a.attnum INTO set_attnum FROM pg_catalog.pg_attribute a
     WHERE a.attrelid = $1 AND a.attname = $2;
    IF $2 IS NOT NULL AND set_attnum IS NULL THEN
        RAISE EXCEPTION 'column "%" not found in relation "%"', $2, $1;
    END IF;

    DELETE FROM dbms_stats.column_stats_locked
     WHERE (starelid = $1 OR $1 IS NULL)
       AND (staattnum = set_attnum OR $2 IS NULL);

    IF $1 IS NOT NULL AND $2 IS NOT NULL THEN
        RETURN QUERY
            SELECT $1;
    END IF;
    FOR unlock_id IN
        SELECT ru.relid
          FROM dbms_stats.relation_stats_locked ru
         WHERE (ru.relid = $1 OR $1 IS NULL) AND ($2 IS NULL)
         ORDER BY ru.relid
    LOOP
        DELETE FROM dbms_stats.relation_stats_locked ru
         WHERE ru.relid = unlock_id;
        RETURN NEXT unlock_id;
    END LOOP;
END;
$$
LANGUAGE plpgsql;

CREATE FUNCTION dbms_stats.unlock_database_stats()
  RETURNS SETOF regclass AS
$$
DECLARE
    unlock_id int8;
BEGIN
    LOCK dbms_stats.relation_stats_locked IN EXCLUSIVE MODE;

    FOR unlock_id IN
        SELECT relid
          FROM dbms_stats.relation_stats_locked
         ORDER BY relid
    LOOP
        DELETE FROM dbms_stats.relation_stats_locked
         WHERE relid = unlock_id;
        RETURN NEXT unlock_id;
    END LOOP;
END;
$$
LANGUAGE plpgsql STRICT;

CREATE FUNCTION dbms_stats.unlock_schema_stats(
    schemaname text
) RETURNS SETOF regclass AS
$$
DECLARE
    unlock_id int8;
BEGIN
    IF NOT EXISTS(SELECT * FROM pg_namespace WHERE nspname = $1) THEN
        RAISE EXCEPTION 'schema "%" not found', $1;
    END IF;
    IF dbms_stats.is_system_schema($1) THEN
        RAISE EXCEPTION 'unlocking statistics is not allowed for system schemas: "%"', $1;
    END IF;

    FOR unlock_id IN
        SELECT r.relid
          FROM dbms_stats.relation_stats_locked r, pg_class c, pg_namespace n
         WHERE relid = c.oid
           AND c.relnamespace = n.oid
           AND n.nspname = $1
         ORDER BY relid
         FOR UPDATE
    LOOP
        DELETE FROM dbms_stats.relation_stats_locked
         WHERE relid = unlock_id;
        RETURN NEXT unlock_id;
    END LOOP;
END;
$$
LANGUAGE plpgsql STRICT;

CREATE FUNCTION dbms_stats.unlock_table_stats(relid regclass)
  RETURNS SETOF regclass AS
$$
DELETE FROM dbms_stats.relation_stats_locked
 WHERE relid = $1
 RETURNING relid::regclass
$$
LANGUAGE sql STRICT;

CREATE FUNCTION dbms_stats.unlock_table_stats(
    schemaname text,
    tablename text
) RETURNS SETOF regclass AS
$$
DELETE FROM dbms_stats.relation_stats_locked
 WHERE relid = dbms_stats.relname($1, $2)::regclass
 RETURNING relid::regclass
$$
LANGUAGE sql STRICT;

CREATE FUNCTION dbms_stats.unlock_column_stats(
    relid regclass,
    attname text
) RETURNS SETOF regclass AS
$$
DECLARE
    set_attnum int2;
BEGIN
    SELECT a.attnum INTO set_attnum FROM pg_catalog.pg_attribute a
     WHERE a.attrelid = $1 AND a.attname = $2;
    IF $2 IS NOT NULL AND set_attnum IS NULL THEN
        RAISE EXCEPTION 'column "%" not found in relation "%"', $2, $1;
    END IF;

	/* Lock the locked table stats */
    PERFORM * from dbms_stats.relation_stats_locked r
        WHERE r.relid = $1 FOR SHARE;

    DELETE FROM dbms_stats.column_stats_locked
      WHERE starelid = $1
        AND staattnum = set_attnum;

    RETURN QUERY
        SELECT $1;
END;
$$
LANGUAGE plpgsql STRICT;

CREATE FUNCTION dbms_stats.unlock_column_stats(
    schemaname text,
    tablename text,
    attname text
) RETURNS SETOF regclass AS
$$
DECLARE
    set_attnum int2;
BEGIN
    SELECT a.attnum INTO set_attnum FROM pg_catalog.pg_attribute a
     WHERE a.attrelid = dbms_stats.relname($1, $2)::regclass
       AND a.attname = $3;
    IF $3 IS NOT NULL AND set_attnum IS NULL THEN
		RAISE EXCEPTION 'column "%" not found in relation "%.%"', $3, $1, $2;
    END IF;

	/* Lock the locked table stats */
	PERFORM * from dbms_stats.relation_stats_locked r
        WHERE  relid = dbms_stats.relname($1, $2)::regclass FOR SHARE;

    DELETE FROM dbms_stats.column_stats_locked
      WHERE starelid = dbms_stats.relname($1, $2)::regclass
        AND staattnum = set_attnum;

    RETURN QUERY
        SELECT dbms_stats.relname($1, $2)::regclass;
END;
$$
LANGUAGE plpgsql STRICT;

--
-- IMPORT_STATS: Statistics import functions
--

CREATE FUNCTION dbms_stats.import(
    nspname text DEFAULT NULL,
    relid regclass DEFAULT NULL,
    attname text DEFAULT NULL,
    src text DEFAULT NULL
) RETURNS void AS
'MODULE_PATHNAME', 'dbms_stats_import'
LANGUAGE C;

CREATE FUNCTION dbms_stats.import_database_stats(src text)
  RETURNS void AS
$$
SELECT dbms_stats.import(NULL, NULL, NULL, $1)
$$
LANGUAGE sql;

CREATE FUNCTION dbms_stats.import_schema_stats(
    schemaname text,
    src text
) RETURNS void AS
$$
SELECT dbms_stats.import($1, NULL, NULL, $2)
$$
LANGUAGE sql;

CREATE FUNCTION dbms_stats.import_table_stats(
    relid regclass,
    src text
) RETURNS void AS
$$
SELECT dbms_stats.import(NULL, $1, NULL, $2)
$$
LANGUAGE sql;

CREATE FUNCTION dbms_stats.import_table_stats(
    schemaname text,
    tablename text,
    src text
) RETURNS void AS
$$
SELECT dbms_stats.import(NULL, dbms_stats.relname($1, $2)::regclass, NULL, $3)
$$
LANGUAGE sql;

CREATE FUNCTION dbms_stats.import_column_stats(
    relid regclass,
    attname text,
    src text
) RETURNS void AS
$$
SELECT dbms_stats.import(NULL, $1, $2, $3)
$$
LANGUAGE sql;

CREATE FUNCTION dbms_stats.import_column_stats(
    schemaname text,
    tablename text,
    attname text,
    src text
) RETURNS void AS
$$
SELECT dbms_stats.import(NULL, dbms_stats.relname($1, $2)::regclass, $3, $4)
$$
LANGUAGE sql;

--
-- PURGE_STATS: Statistics purge function
--
CREATE FUNCTION dbms_stats.purge_stats(
    backup_id int8,
    force bool DEFAULT false
) RETURNS SETOF dbms_stats.backup_history AS
$$
DECLARE
    delete_id int8;
    todelete   dbms_stats.backup_history;
BEGIN
    IF $1 IS NULL THEN
        RAISE EXCEPTION 'backup id required';
    END IF;
    IF $2 IS NULL THEN
        RAISE EXCEPTION 'NULL is not allowed as the second parameter';
    END IF;

    IF NOT EXISTS(SELECT * FROM dbms_stats.backup_history
                  WHERE id = $1 FOR UPDATE) THEN
        RAISE EXCEPTION 'backup id % not found', $1;
    END IF;
    IF NOT $2 AND NOT EXISTS(SELECT *
                               FROM dbms_stats.backup_history
                              WHERE unit = 'd'
                                AND id > $1) THEN
        RAISE WARNING 'no database-wide backup will remain after purge'
			USING HINT = 'Give true for second parameter to purge forcibly.';
        RETURN;
    END IF;

    FOR todelete IN
        SELECT * FROM dbms_stats.backup_history
         WHERE id <= $1
         ORDER BY id FOR UPDATE
    LOOP
        DELETE FROM dbms_stats.backup_history
         WHERE id = todelete.id;
        RETURN NEXT todelete;
    END LOOP;
END;
$$
LANGUAGE plpgsql;

--
-- CLEAN_STATS: Clean orphan dummy statistics
--
CREATE FUNCTION dbms_stats.clean_up_stats() RETURNS SETOF text AS
$$
DECLARE
	clean_relid		Oid;
	clean_attnum	int2;
	clean_inherit	bool;
	clean_rel_col	text;
BEGIN
	-- We don't have to check that table-level dummy statistics of the table
	-- exists here, because the foreign key constraints defined on column-level
	-- dummy static table ensures that.
	FOR clean_rel_col, clean_relid, clean_attnum, clean_inherit IN
		SELECT r.relname || ', ' || v.staattnum::text,
			   v.starelid, v.staattnum, v.stainherit
		  FROM dbms_stats.column_stats_locked v
		  JOIN dbms_stats.relation_stats_locked r ON (v.starelid = r.relid)
		 WHERE NOT EXISTS (
			SELECT NULL
			  FROM pg_attribute a
			 WHERE a.attrelid = v.starelid
			   AND a.attnum = v.staattnum
			   AND a.attisdropped  = false
         FOR UPDATE
		)
	LOOP
		DELETE FROM dbms_stats.column_stats_locked
		 WHERE starelid = clean_relid
		   AND staattnum = clean_attnum
		   AND stainherit = clean_inherit;
		RETURN NEXT clean_rel_col;
	END LOOP;

	RETURN QUERY
		DELETE FROM dbms_stats.relation_stats_locked r
		 WHERE NOT EXISTS (
			SELECT NULL
			  FROM pg_class c
			 WHERE c.oid = r.relid)
		 RETURNING relname || ',';
	RETURN;
END
$$
LANGUAGE plpgsql;
--
