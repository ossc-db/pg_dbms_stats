

------------------------------------------------------------------------

<div class="index">

1.  [NAME](#name)
2.  [SYNOPSIS](#synopsis)
3.  [DESCRIPTION](#description)
4.  [INSTALLATION](#installation)
5.  [UNINSTALLATION](#uninstallation)
6.  [USAGE EXAMPLES](#usage-examples)
7.  [RESTRICTIONS](#restrictions)
8.  [UNDER THE HOOD](#under-the-hood)
9.  [ENVIRONMENT](#environment)
10. [SEE ALSO](#see-also)
11. [Appendix A. TARGET OBJECTS LIST](objects-en.md)

</div>

# pg_dbms_stats 14.0
---

## NAME

pg_dbms_stats -- controls planner behavior by giving stored table statistics.

## SYNOPSIS

PostgreSQL manages table statistics from sampled values of tables and
indexes by ANALYZE command. Query optimizer calculates execution plan
costs based on the statistics and chooses the plan with the lowest cost.
On the mechanism, inaccuracy of statisctics or sudden change of data
amount or distribution lets the query optimizer make unexpected or
unwanted change of execution plan.

pg_dbms_stats is a extension that try to stabilize execution plan
avoiding such kind of disturbance. It tries to stabilize planning by
providing predefined "dummy" statistics instead of original values for
requests from the planner. It is intended to be used by those who want
to lower the risk that a unexpected change of execution plan leands to
bad performance degradation on a system.

pg_dbms_stats can fix the statistics of the following database objects.

-   Ordinary tables
-   Idexes (having a restriction except for function indexes)
-   Foreign tables(PG9.2 and later)
-   Materialied views

## DESCRIPTION

There are eight kind of operations pg_dbms_stats offers for manipulating
statistics used by planner. All operations other than export are
executed via SQL functions。See [TARGET OBEJCT LIST](objects-en.md)
for details.

### BACKUP

DESCRIPTION  
- Store the statistics that planner currently sees for later use to let the planner behave in the same way as now.

USAGE  
- Execute the SQL function backup\_\<restore_unit\>\_stats()

DETAILS  
- The objects to store their statistics are specified by the unit of the whole databsae, schema, table and column. For example, specify the schema when you want to store the statistics of all tables and columns in a schema. To keep things simple, it would be a good practice to specify the target objects in rather large sized unit like database or schema.

The backup history is seen in dbms_stats.backup_history table. The details are seen in [TABLES](objects-en.md#table).

### RESTORE

DESCRIPTION  
- Choose and load a backuped statistics so that planner behaves in the same way as the time of the backup.

USAGE  
- Execute SQL functions restore_stats() or restore\_\<restore_unit\>\_stats()

DETAILS  
- Resotore a backuped statistics for the specified objects. Planner continues to see the same statistics for others. There are following two ways to specify a backup.

- Backup ID
    - By invoking the function restore_stats() with a backup ID, the backup with the ID is restored. It is the simplest way to restore a whole backup when you take backups in units of database or schema. The backup ID is unique within a database so make sure use a backup ID of the right database.
- Object type and timestamp
    - By invoking the SQL function restore\_\<restore_unit\>\_stats() with a timestamp, the statistics of the all objects in the specfied unit are restored from the latest backup of each object before the specified time. Planner sees the "real" statistics for the objects that don't have a backup before the time. This method is useful when you are taking statistics backups by smaller units and it is difficult to identify a set of backup IDs to restore the status at a certain time.
- Restore implies "lock" of statistics. No need of explicit lock of statitics after restoration.

### PURGE

DESCRIPTION  
- Performs a bulk deletion of backups no longer necessary. All backups taken before the speccified backup ID are deleted.

USAGE  
- Execute the SQL function purge_stats() with a backup ID.

DETAILS  
- The backup ID must be specified to leave at least one database-wise backup but this restriction can be omitted by giving true as the "force" parameter.

### LOCK

DESCRIPTION  
- Stores the statistics at the time and show it to planner to let it behave in the same way thereafter.

USAGE  
- Execute the SQL function lock\_\<lock unit\>\_stats() with the name of the target unit.

DETAILS  
- The lock units are one of database, schema, table or column.

### UNLOCK

DESCRIPTION  
- Deletes locked statistics and planner behaves in ordinary way thereafter.

USAGE  
- Execute the SQL function unlock\_\<unlock unit\>\_stats() with the name of the target unit.

DETAILS  
- Planner uses the "real" statitics stored in pg_class and pg_statistic for an object after unlocking of the object. The unlock unit is one of database, schema table and column. Unlock is allowed to execute with arbitrary unit unrelated to the unit specified as of locking.

### CLEANUP

DESCRIPTION  
- Remove all locked statistics of objects no longer exisrts.

USAGE  
- Execute the SQL function clean_up_stats()

DETAILS  
- Dropping a table or a column doesn't delete locked statistics automatically. This function removes such orphan locked statistics at once.

### EXPORT

DESCRIPTION  
- Write out the current statistics to an external file.

USAGE  
- Craft an SQL script based on the sample SQL files (export\_\<stats type\>\_stats-\<PG version\>.sql.sample) then execute it. "stats type"- is one of plain or effective, which means the real statistics and the statistics pg_dbms_stats will offer respectively.

DETAILS  
- Choose one of plain or effective according to the purpose. The output directory must be writable by the user which is running the server.

- The "real" statistics of PostgreSQL  
    - The statistics stored in pg_class and pg_statistics. This is usable for off-site analysis and tuning of a server. The exported statistics can be loaded using pg_dbms_stats on the analysing site.
- The statitics currently in effect  
    - The statistics that planner is looking through pg_dbms_stats. It is usable for loading a tuned statistics onto the service site or backing up an effective statitics into a plain file.
- You can find the sample files in the "extension" subdirectory in the directory shown by "pg_config --docdir".

### IMPORT

DESCRIPTION  
- Loads a plain file created by export and use it as a locked statistics.

USAGE  
- Execute the SQL function import\_\<load unit\>\_stats() with object name and the file to load.

DETAILS  
- The load unit is one of database, schema, table and column. The data in the import file that is out of the specified load unit is excluded on loading. The import file must be placed so that the server can read it.

## INSTALLATION

pg_dbms_stats can be installed in the ordinary method to load an extension.

### BUILD

Just type "make" after setting PATH environment variable so that the
right pg_config is executed. Then type "make install"by the same user
with the installed server.

### REGISTER AS AN EXTENSION

pg_dbms_stats is a PostgreSQL extension, which requires "CREATE EXTENSION" to be executed.

Extension itself is dropped by DROP EXTENSION but the dbms_stats is left in place.
Drop it manually if no longer needed.

### LOADING pg_dbms_stats

pg_dbms_stats is dynamically loadable using LOAD command. If you want
enable pg_dbms_stats automatically in all sessions, add "pg_dbms_stats"
to shared_preload_libraries in postgresql.conf then restart the server.

**CAVEAT**: You will see the following lines in the log file for every
statement by just loading pg_dbms_stats but not registering as an
extension on the database. Make sure regstering on the database before
you load pg_dbms_stats.

    test=# SELECT * FROM test;
    ERROR:  schema "dbms_stats" does not exist
    LINE 1: SELECT relpages, reltuples, curpages  FROM dbms_stats.relati...
                                                       ^
    QUERY:  SELECT relpages, reltuples, curpages  FROM dbms_stats.relation_stats_locked WHERE relid = $1
    test=#

### INACTIVATE pg_dbms_stats

To inactivate loaded pg_dbms_stats, set pg_dbms_stats.use_locked_stats
to off.

    test=# SET pg_dbms_stats.use_locked_stats TO off;
    SET
    test=# SELECT * FROM test; -- generates a plan based on the real statistics
    ...
    test=# SET pg_dbms_stats.use_locked_stats TO on;
    SET
    test=# SELECT * FROM test; -- generates a plan based on the locked statistics
    ...

To turn off pg_dbms_stats on all sessions, set
pg_dbms_stats.use_locked_stats to off in postgresql.conf then reload the
config, or use ALTER SYSTEM for PG9.4 or later.

## UNINSTALLATION

Perform the following steps to uninstall pg_dbms_stats. *dbname* is the
name of the databases on which pg_dbms_stats is regsistered as an
extension.

1.  Type "make uninstall" in the build directory as the installation
    user.
2.  Enter "DROP EXTENSION" command on all databases that pg_dbms_stats
    is registered as an extension.
3.  Remove dbms_stats schema if you no longer need the locked or backed
    up statistics.

## USAGE EXAMPLES

There are roughly three kind of operation styles. Mainly-backing-up,
mainly-locking, mainly-exporting. Assume mainly-backup style if you are
not sure which one of them fits your requirement.

### "MAINLY-BACKING-UP" OPERATION

Take daily backups using backup_xxx() functions and restore only
required statistics when you face a problem using restore_xxx()
functions. Take database-wise backup if you don't have special
requirements.

Restore the backed up statistics by specifying by backup ID or
timestamp. Use backup ID unless you have difficulties to identify the
target ID.

    -- Take a daily backup then ANALYZE.
    test=# SELECT dbms_stats.backup_database_stats('any comment');
     backup_database_stats
    -----------------------
                         1
    (1 row)

    test=# ANALYZE;
    ANALYZE
    test=#

    -- Restore and lock the statistics at the same time yesterday.
    test=# SELECT dbms_stats.restore_database_stats(now() - '1 day');

**CAVEAT**: As explained above, if there are no backups before the
specified time for some columns or tables planner continues to see the
statistics before the restoration. This might lead to unexpected
behavior of planner.

The following is an example of restore operation of a statistics backup.
The "time" column shows the time of the backup.

    test=# SELECT b.id, b.time, r.relname
         FROM dbms_stats.relation_stats_backup r
         JOIN dbms_stats.backup_history b ON (r.id=b.id)
        ORDER BY id;
     id |          time          |     relname
    ----+------------------------+-----------------
      4 | 2012-01-01 00:00:00+09 | public.droptest
      5 | 2012-01-02 12:00:00+09 | public.test
    (5 rows)

    test=# SELECT dbms_stats.restore_database_stats('2012-01-03 00:00:00+09');
     restore_database_stats
    ------------------------
     test
     droptest
    (2 rows)

    test=#

### "MAINLY-LOCKING" OPERATION

Execute lock_xxx() functions to just lock the statistics at the servicestart.

    test=# SELECT dbms_stats.lock_database_stats();
     lock_database_stats
    ---------------------
     droptest
     test
    (2 rows)

    test=#

### "MAINLY-EXPORTING" OPERATION

To export the statistics under operation then import into another
database, craft and execute a script based on the
export_xxx_stats-.sql_samplefiles then execute import_xxx() function on
the another database.

    $ cd pg_dbms_stats
    $ psql -d test -f export_effective_stats-10.sql
    BEGIN
    COMMIT
    $ psql -d test2 -c "SELECT dbms_stats.import_database_stats('$PWD/export_stats.dmp')"
     import_database_stats
    -----------------------

    (1 row)

    $

CAVEAT: The base script uses binary format of COPY command so import
might fail if the format is incompatible with the export side. See [COPY
command](http://www.postgresql.jp/document/current/html/sql-copy.html) for details.

Import of exported statistics into PostgreSQL servers of different major versions is not supported. Even if the import appears to be successful, there is a good chance that the subsequent server operation will be unstable and the expected execution plan will not be obtained.

## RESTRICTIONS

There are some important poins and restrictions to use pg_dbms_stats.

Prerequisites  
- Make sure that the target objects have statistics before performing lock or backup of pg_dbms_stats. The operations in the case don't work as expected although you won't have no error message.

Limitations on fixable objects  
- Since the ordinary index (that is, non-function/formula index) doesn't have column-wise statistics, columns-wise lock or backup does nothing.

Timing of statistics backup  
- Database triggers cannot be used to automatically invoke locking or backing-up of statistics. Use external tools to run the set of ANALYZE and statistics backup as a job.

Other factors of planning change  
- Since this tool stores only statistics, despite of statistics locking the planner's behavior may change by settings of several [GUC paremeters](http://www.postgresql.jp/document/current/html/runtime-config-query.html) that affect planning or significant change of the density of a relation.

Possible hook confclicts  
- Since pg_dbms_stats uses the following hook points it might conflict with tools that uses the same hook points.

    -   get_relation_info_hook
    -   get_attavgwidth_hook
    -   get_relation_stats_hook
    -   get_index_stats_hook

Cautions on dump and restore of the database  
- pg_dbms-stats uses anyarray type to store column statistics. The type information will be lost by dumping the values in text representation and restore will fail. Take the following steps to restore dbms_stats schema properly.

1.  Dump the statistics managed by pg_dbms_stats in binary format into
    &ltfile name\>.
2.  Dump the other schemas in the an ordinary method.
3.  Restore the dump file.
4.  Install pg_dbms_stats.
5.  Load the &ltfile name\> into the tables in dbms_statas schema.

Supported access methods
- The objects supported by pg_dbms_stats are tables / materialized views / Foreign tables / indexes. Of these, the table only supports heap, not those that use other access methods.

## UNDER THE HOOD

### Outline

pg_dbms_stats lets planner to see dummy statistics instead of the real statistics 
it usually sees and stabilizes the execution plans. There are three sources of the dummy statistics.

- Perform "lock" using the statistics at the present.
- Perform "restore" using a backup.
- Perform "import" using an exported file.

pg_dbms_stats manages statistics using several tables and files.

Currently effective statistics  
- Ths statistics planner actually sees, which is made by lock, restore or import functions.

Backed-up statistics  
- A set of statistics at a certain time generated by the backup feature of pg_dbms_stats. pg_dbms_stats can manage multiple backup sets in the history table. These backups is loaded in plance of the currently effective statistics by using restore function.

Exported statistics  
- A set of statistics on a database generated as an OS file by the export function. Multiple sets of statistics are exportable with different names. The exported statistics is loaded in place of the currently effective statistics by using import function.

pg_dbms_stats doesn't change the real statistics shown in pg_class or pg_statistic catalogs.

![](pg_dbms_stats-ja.png)

### User interface of pg_dbms_stats

pg_dbms_stats manages statistics by updating the content of the
statistics tables mentioned above. pg_dbms_stats provides the management
SQL functions to update the tables keeping consistency. Manually
manipulating the tables is discouraged.

### Statistics items pg_dbms_stats locks

Planner calculates the cost of an execution plan based on the following
statistics items or the real values. pg_dbms_stats locks or stores all
of these statistics items. It even conceals the change of the size of
relation files by replaceing with the size at the time of locked or
backed-up.

-   column value statistics calculated by ANALYZE
    (pg_catalog.pg_statistic)
-   number of tuples estimated by ANALYZE
    (pg_catalog.pg_class.reltuples)
-   relation file size at the time of ANALYZE
    (pg_catalog.pg_class.relpages)
-   relation file size at the time of planning

### Manually operation of statistics

Some columns in the statistics tables are of anyarray type thus they are
inoperable from the genuine SQL interface. pg_dbms_stats has helper
functions to manipulate the values of the columns since 1.3.7. This
feature doesn't offer any fool-proof protection and improper
manipulation not only lets planner do wrong but easily leads to a server
crash. Be careful in using this feature.

#### Usage

You can inject values by the following three steps.

-   Identification of the base type of the anyarray for the target
    statistics item.

    You can do that by invoking anyarray_basetype() function giving the
    name of the target statistics column in column_stats_locked table.

        =# SELECT dbms_stats.anyarray_basetype(stavalues1)
           FROM dbms_stats.column_stats_locked
           WHERE starelid = xxxx AND staattnum = x;
         anyarray_basetype
         -------------------
          float4
         (1 row)

-   Preparation for injecting an array of the crafted values of the base
    type as the dummy statistics.

    A helper function and a cast required to inject dummy statistics are
    generated by invoking prepare_statstweak() function with giving the
    target base type as a text. The stuff is removed by
    drop_statstweak().

        =# SELECT dbms_stats.prepare_statstweak('float4');
            -----------------------------------------------------------------------------------
             (func dbms_stats._realary_anyarray(real[]), cast (real[] AS dbms_stats.anyarray))
            (1 row)

-   Injection of statistics

    Everything is ready. The following statement updates the dummy
    statistics item.

        =# UPDATE dbms_stats.column_stats_locked
            SET stavalues1 = '{1.1,2.2,3.3}'::float4[]
            WHERE starelid = xxxx AND staattnum = x;
         UPDATE 1

## ENVIRONMENT

PostgreSQL  
14

OS  
RHEL 7/8

## SEE ALSO

[psql](http://www.postgresql.jp/document/current/html/app-psql.html),
[vacuumdb](http://www.postgresql.jp/document/current/html/app-vacuumdb.html)
[COPY](http://www.postgresql.jp/document/current/html/sql-copy.html)

------------------------------------------------------------------------

Copyright (c) 2009-2022, NIPPON TELEGRAPH AND TELEPHONE CORPORATION
