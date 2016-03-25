/* pg_dbms_stats/pg_dbms_stats--1.3.6--1.3.7.sql */

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "ALTER EXTENSION pg_dbms_stats UPDATE TO '1.3.7'" to load this file. \quit

/*
 * Stuff for manipulating statistics
 */

/* Primitive functions for tweaking statistics */
CREATE FUNCTION dbms_stats.anyarray_basetype(dbms_stats.anyarray)
	RETURNS name
	AS 'MODULE_PATHNAME', 'dbms_stats_anyarray_basetype'
	LANGUAGE C STABLE;

CREATE FUNCTION dbms_stats.type_is_analyzable(oid) returns bool
	AS 'MODULE_PATHNAME', 'dbms_stats_type_is_analyzable'
	LANGUAGE C STRICT STABLE;

/*
 * Create and drop a cast necessary to set column values of dbms_stats.anyarray
 * type.
 */
CREATE OR REPLACE FUNCTION dbms_stats.prepare_statstweak(regtype)
RETURNS text AS $$
DECLARE
  srctypname varchar;
  funcname varchar;
  funcdef varchar;
  castdef varchar;
BEGIN
  srctypname := $1 || '[]';
  funcname := 'dbms_stats._' || replace($1::text, ' ', '_') || '_ary_anyarray';
  funcdef := funcname || '(' || srctypname || ')';
  castdef := '(' || srctypname || ' AS dbms_stats.anyarray)';

  IF (NOT dbms_stats.type_is_analyzable($1::regtype)) THEN
    RAISE 'the type can not have statistics';
  END IF;

  EXECUTE 'CREATE FUNCTION ' || funcdef || 
          ' RETURNS dbms_stats.anyarray ' ||
          ' AS ''pg_dbms_stats'', ''dbms_stats_anyary_anyary'''||
          ' LANGUAGE C STRICT IMMUTABLE';
  EXECUTE 'CREATE CAST '|| castdef ||
	      ' WITH FUNCTION ' || funcdef ||
	      ' AS ASSIGNMENT';
  RETURN '(func ' || funcdef || ', cast ' || castdef || ')';
EXCEPTION
  WHEN duplicate_function THEN
    RAISE 'run dbms_stats.drop_statstweak() for the type before this';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION dbms_stats.drop_statstweak(regtype)
RETURNS text AS $$
DECLARE
  srctypname varchar;
  funcname varchar;
  funcdef varchar;
  castdef varchar;
BEGIN
  srctypname := $1 || '[]';
  funcname := 'dbms_stats._' || replace($1::text, ' ', '_') || '_ary_anyarray';
  funcdef := funcname || '(' || srctypname || ')';
  castdef := '(' || srctypname || ' AS dbms_stats.anyarray)';

  EXECUTE 'DROP CAST ' || castdef;
  EXECUTE 'DROP FUNCTION ' || funcdef;
  RETURN '(func ' || funcdef || ', cast ' || castdef || ')';
EXCEPTION
  WHEN undefined_function OR undefined_object THEN
    RAISE 'function % or cast % does not exist', funcdef, castdef;
END;
$$ LANGUAGE plpgsql;
