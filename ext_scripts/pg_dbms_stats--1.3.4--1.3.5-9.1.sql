/* pg_dbms_stats/pg_dbms_stats--1.3.4--1.3.5.sql */

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "ALTER EXTENSION pg_dbms_stats UPDATE TO '1.3.5'" to load this file. \quit

/* Dropping unnecessary views and rename tables  */
ALTER EXTENSION pg_dbms_stats DROP VIEW dbms_stats.relation_stats_locked;
DROP VIEW dbms_stats.relation_stats_locked;
ALTER EXTENSION pg_dbms_stats DROP VIEW dbms_stats.column_stats_locked;
DROP VIEW dbms_stats.column_stats_locked;

ALTER TABLE dbms_stats._relation_stats_locked
	  RENAME TO relation_stats_locked;
ALTER TABLE dbms_stats._column_stats_locked
	  RENAME TO column_stats_locked;

ALTER INDEX dbms_stats._relation_stats_locked_pkey
	  RENAME TO relation_stats_locked_pkey;
ALTER INDEX dbms_stats._column_stats_locked_pkey
	  RENAME TO column_stats_locked_pkey;
-- ALTER TABLE RENAME CONSTRAINT is since 9.2
-- ALTER TABLE dbms_stats.column_stats_locked
-- 	  RENAME CONSTRAINT _column_stats_locked_starelid_fkey
--	  		 TO column_stats_locked_starelid_fkey;
UPDATE pg_constraint
	   SET conname = 'column_stats_locked_starelid_fkey'
	   WHERE oid =
	   		 (SELECT cn.oid
			  FROM pg_constraint cn
			  JOIN pg_namespace n ON (n.nspname = 'dbms_stats' AND n.oid = cn.connamespace)
			  WHERE cn.conname = '_column_stats_locked_starelid_fkey');

/* Change function and view defenitions */
CREATE OR REPLACE FUNCTION dbms_stats.merge(
    lhs dbms_stats.column_stats_locked,
    rhs pg_catalog.pg_statistic
) RETURNS dbms_stats.column_stats_locked AS
'MODULE_PATHNAME', 'dbms_stats_merge'
LANGUAGE C STABLE;

CREATE OR REPLACE VIEW dbms_stats.relation_stats_effective AS
    SELECT
        c.oid AS relid,
        dbms_stats.relname(nspname, c.relname) AS relname,
        COALESCE(v.relpages, c.relpages) AS relpages,
        COALESCE(v.reltuples, c.reltuples) AS reltuples,
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

CREATE OR REPLACE VIEW dbms_stats.column_stats_effective AS
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

CREATE OR REPLACE   FUNCTION dbms_stats.restore(
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
                RAISE EXCEPTION 'statistics of column "%" of relation "%" are not found in any backups before backup id = %',$3, $2, $1;
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
                       stakind1, stakind2, stakind3, stakind4,
                       staop1, staop2, staop3, staop4,
                       stanumbers1, stanumbers2, stanumbers3, stanumbers4,
                       stavalues1, stavalues2, stavalues3, stavalues4
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

CREATE OR REPLACE FUNCTION dbms_stats.restore_stats(
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
                       stakind1, stakind2, stakind3, stakind4,
                       staop1, staop2, staop3, staop4,
                       stanumbers1, stanumbers2, stanumbers3, stanumbers4,
                       stavalues1, stavalues2, stavalues3, stavalues4
                  FROM dbms_stats.column_stats_backup
                 WHERE id = $1
                   AND starelid = restore_relid
                   AND staattnum = restore_attnum;
        END IF;
    END LOOP;

END;
$$
LANGUAGE plpgsql STRICT;

CREATE OR REPLACE FUNCTION dbms_stats.lock(
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
               stakind1, stakind2, stakind3, stakind4,
               staop1, staop2, staop3, staop4,
               stanumbers1, stanumbers2, stanumbers3, stanumbers4,
               stavalues1, stavalues2, stavalues3, stavalues4
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
               staop1 = r.staop1,
               staop2 = r.staop2,
               staop3 = r.staop3,
               staop4 = r.staop4,
               stanumbers1 = r.stanumbers1,
               stanumbers2 = r.stanumbers2,
               stanumbers3 = r.stanumbers3,
               stanumbers4 = r.stanumbers4,
               stavalues1 = r.stavalues1,
               stavalues2 = r.stavalues2,
               stavalues3 = r.stavalues3,
               stavalues4 = r.stavalues4
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
                         r.staop1,
                         r.staop2,
                         r.staop3,
                         r.staop4,
                         r.stanumbers1,
                         r.stanumbers2,
                         r.stanumbers3,
                         r.stanumbers4,
                         r.stavalues1,
                         r.stavalues2,
                         r.stavalues3,
                         r.stavalues4);
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

CREATE OR REPLACE FUNCTION dbms_stats.lock(relid regclass)
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
			USING HINT = 'Only tables(r) and indexes(i) are lockable.';
    END IF;
    IF dbms_stats.is_system_catalog($1) THEN
		RAISE EXCEPTION 'locking statistics is not allowed for system catalogs: "%"', $1;
    END IF;

    UPDATE dbms_stats.relation_stats_locked r
       SET relname = dbms_stats.relname(nspname, c.relname),
           relpages = v.relpages,
           reltuples = v.reltuples,
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
               v.relpages, v.reltuples, v.curpages,
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
               stakind1, stakind2, stakind3, stakind4,
               staop1, staop2, staop3, staop4,
               stanumbers1, stanumbers2, stanumbers3, stanumbers4,
               stavalues1, stavalues2, stavalues3, stavalues4
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
               staop1 = i.staop1,
               staop2 = i.staop2,
               staop3 = i.staop3,
               staop4 = i.staop4,
               stanumbers1 = i.stanumbers1,
               stanumbers2 = i.stanumbers2,
               stanumbers3 = i.stanumbers3,
               stanumbers4 = i.stanumbers4,
               stavalues1 = i.stavalues1,
               stavalues2 = i.stavalues2,
               stavalues3 = i.stavalues3,
               stavalues4 = i.stavalues4
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
                         i.staop1,
                         i.staop2,
                         i.staop3,
                         i.staop4,
                         i.stanumbers1,
                         i.stanumbers2,
                         i.stanumbers3,
                         i.stanumbers4,
                         i.stavalues1,
                         i.stavalues2,
                         i.stavalues3,
                         i.stavalues4);
            END IF;
        END LOOP;

    RETURN $1;
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'This operation is canceled by simultaneous lock operation on the same relation.';
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION dbms_stats.unlock(
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

CREATE OR REPLACE FUNCTION dbms_stats.unlock_database_stats()
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

CREATE OR REPLACE FUNCTION dbms_stats.unlock_schema_stats(
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

CREATE OR REPLACE FUNCTION dbms_stats.unlock_table_stats(relid regclass)
  RETURNS SETOF regclass AS
$$
DELETE FROM dbms_stats.relation_stats_locked
 WHERE relid = $1
 RETURNING relid::regclass
$$
LANGUAGE sql STRICT;

CREATE OR REPLACE FUNCTION dbms_stats.unlock_table_stats(
    schemaname text,
    tablename text
) RETURNS SETOF regclass AS
$$
DELETE FROM dbms_stats.relation_stats_locked
 WHERE relid = dbms_stats.relname($1, $2)::regclass
 RETURNING relid::regclass
$$
LANGUAGE sql STRICT;

CREATE OR REPLACE FUNCTION dbms_stats.unlock_column_stats(
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

CREATE OR REPLACE FUNCTION dbms_stats.unlock_column_stats(
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

CREATE OR REPLACE FUNCTION dbms_stats.clean_up_stats() RETURNS SETOF text AS
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
