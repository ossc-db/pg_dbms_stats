/*
 * No.1-1 CREATE EXTENSION
 */
-- No.1-1-1
CREATE EXTENSION pg_dbms_stats;
-- No.1-1-2
DROP EXTENSION pg_dbms_stats;

CREATE EXTENSION pg_dbms_stats;

-- create no superuser and superuser
SET client_min_messages = warning;
DROP ROLE IF EXISTS regular_user;
CREATE ROLE regular_user LOGIN;
SET client_min_messages = fatal;
CREATE ROLE postgres SUPERUSER CREATEDB CREATEROLE INHERIT LOGIN;

-- create object
CREATE TABLE pt0(id integer, day date);
CREATE INDEX pt0_idx ON pt0(id);
CREATE TABLE st0(id integer, name char(5));
CREATE INDEX st0_idx ON st0(id);
CREATE TABLE st1(val integer, str text);

CREATE SCHEMA s0;
CREATE TABLE s0.st0(id integer, num integer);
CREATE INDEX st0_idx ON s0.st0(id);
CREATE TABLE s0.st1() INHERITS(s0.st0);
CREATE INDEX st1_idx ON s0.st1(id);
CREATE TABLE s0.st2(id integer, txt text);
CREATE INDEX st2_idx ON s0.st2(id);
CREATE VIEW sv0 AS
    SELECT st0.id, st0.num, st2.txt
      FROM s0.st0 st0, s0.st2 st2
     WHERE st0.id = st2.id;
CREATE TYPE s0.sc0 AS (num integer, txt text);
CREATE SEQUENCE s0.ss0 START 1;

CREATE SCHEMA s1;
CREATE TABLE s1.st0(id integer, num integer);
CREATE SCHEMA s2;

GRANT USAGE ON SCHEMA s0 TO regular_user;
GRANT SELECT ON TABLE s0.st2 TO regular_user;

CREATE TYPE complex AS (
     r double precision,
     i double precision
);

CREATE FUNCTION inform(VARIADIC arr text[]) RETURNS int AS $$
DECLARE
    str text := 'arguments are ';
    count int;
BEGIN
    FOR count IN SELECT i FROM generate_subscripts($1, 1) g(i) LOOP
        IF count != 1 THEN
            str := str || ', ';
        END IF;
        IF $1[count] IS NULL THEN
            str := str || '<NULL>';
        ELSE
            str := str || $1[count];
        END IF;
    END LOOP;
    RAISE NOTICE '%', str;
    RETURN 1;
END;
$$LANGUAGE plpgsql;

CREATE VIEW lockd_io AS
       SELECT relname,
              heap_blks_read + heap_blks_hit > 0  hb_fetch,
              idx_blks_read  + idx_blks_hit  > 0  ib_fetch
         FROM pg_statio_user_tables
        WHERE schemaname = 'dbms_stats'
          AND relname LIKE '%stats_locked'
        ORDER BY relid;

-- load data
INSERT INTO st0 VALUES (1, 'test'), (2, 'test');
INSERT INTO st1 SELECT i % 3, i % 3 FROM generate_series(1, 10000) t(i);
INSERT INTO s0.st0 VALUES (1, 10), (2, 20);
INSERT INTO s0.st1 VALUES (4, 40), (5, 50), (6, 60);
INSERT INTO s0.st2 VALUES (1, '1'), (2, 'test'), (3, 'comment');
INSERT INTO s1.st0 VALUES (1, 15), (2, 25), (3, 35), (4, 45);

CREATE INDEX st1_idx ON st1 (val);
CREATE INDEX st1_exp ON st1 (lower(str));

VACUUM ANALYZE;
