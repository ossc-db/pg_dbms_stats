/* pg_dbms_stats/pg_dbms_stats--1.0--1.3.2.sql */

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "ALTER EXTENSION pg_dbms_stats UPDATE TO '1.3.2'" to load this file. \quit

-- NOTE: Due to some mistake in version management, the version 1.3.0,
-- 1,3.1 are named as '1.0. So this script upgrades this module from
-- both of the versions.

--
-- Statistics views for internal use
--    These views are used to merge authentic stats and dummy stats by hook
--    function, so we don't grant SELECT privilege to PUBLIC.
--

CREATE OR REPLACE VIEW dbms_stats.column_stats_effective AS
    SELECT * FROM (
        SELECT (dbms_stats.merge(v, s)).*
          FROM pg_catalog.pg_statistic s
          FULL JOIN dbms_stats._column_stats_locked v
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
-- CLEAN_STATS: Clean orphan dummy statistic
--

CREATE OR REPLACE FUNCTION dbms_stats.clean_up_stats() RETURNS SETOF text AS
$$
DECLARE
	clean_relid		Oid;
	clean_attnum	int2;
	clean_inherit	bool;
	clean_rel_col	text;
BEGIN
    LOCK dbms_stats._relation_stats_locked IN SHARE UPDATE EXCLUSIVE MODE;
    LOCK dbms_stats._column_stats_locked IN SHARE UPDATE EXCLUSIVE MODE;

	-- We don't have to check that table-level dummy statistic of the table
	-- exists here, because the foreign key constraints defined on column-level
	-- dummy static table eusures that.
	FOR clean_rel_col, clean_relid, clean_attnum, clean_inherit IN
		SELECT r.relname || ', ' || v.staattnum::text,
			   v.starelid, v.staattnum, v.stainherit
		  FROM dbms_stats._column_stats_locked v
		  JOIN dbms_stats._relation_stats_locked r ON (v.starelid = r.relid)
		 WHERE NOT EXISTS (
			SELECT NULL
			  FROM pg_attribute a
			 WHERE a.attrelid = v.starelid
			   AND a.attnum = v.staattnum
			   AND a.attisdropped  = false
		)
	LOOP
		DELETE FROM dbms_stats._column_stats_locked
		 WHERE starelid = clean_relid
		   AND staattnum = clean_attnum
		   AND stainherit = clean_inherit;
		RETURN NEXT clean_rel_col;
	END LOOP;

	RETURN QUERY
		DELETE FROM dbms_stats._relation_stats_locked r
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
