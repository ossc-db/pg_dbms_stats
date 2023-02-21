\getenv abs_srcdir PG_ABS_SRCDIR
\set csv_path :abs_srcdir '/ut-fdw.csv'

CREATE EXTENSION file_fdw;
CREATE SERVER test_server
       FOREIGN DATA WRAPPER file_fdw;
CREATE FOREIGN TABLE s0.sft0(id integer)
       SERVER test_server
       OPTIONS (filename :'csv_path',
				format 'csv');
\! cp $PG_ABS_SRCDIR/input/ut-fdw.csv $PG_ABS_SRCDIR/ut-fdw.csv