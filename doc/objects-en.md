# pg_dbms_stats 14.0

[pg_dms_stats](pg_dbms_stats-en.md) -> [Appendix A. Object List](objects-en.md)

<div class="index">

1.  [Function](#function)
2.  [Table](#table)
3.  [View](#view)

</div>

## Function

pg_dbms_stats contains the following functions.
Discription of each function.


|Features      |Function                       |Argument |Object Unit|Return Value|
|:-----------|:--------------------------------|:----|:---------------|:-----|
|Backup|dbms_stats.backup_database_stats|comment|Database|int8|
|Backup|dbms_stats.backup_schema_stats  |schemaname、comment|Schema|int8|
|Backup|dbms_stats.backup_table_stats   |relname、comment<br>Or<br>schemaname、tablename、comment|Table|int8|
|Backup|dbms_stats.backup_column_stats  |relname、attname、comment<br>Or<br>schemaname、tablename、attname、comment|Column|int8|
|Restore|dbms_stats.restore_database_stats   |timestamp|Database|regclass|
|Restore|dbms_stats.restore_schema_stats     |schemaname、timestamp|Schema|regclass|
|Restore|dbms_stats.restore_table_stats      |relname、timestamp<br>Or<br>schemaname、tablename、timestamp |Table|regclass|
|Restore|dbms_stats.restore_column_stats     |relname、attname、timestamp<br>Or<br>schemaname、tablename、attname、timestamp|列|regclass|
|Restore|dbms_stats.restore_stats            |backup_id  |Backup|regclass|
|Lock|dbms_stats.lock_database_stats        |(Without)|Database|regclass|
|Lock|dbms_stats.lock_schema_stats          |schemaname|Schema|regclass|
|Lock|dbms_stats.lock_table_stats           |relname<br>Or<br>schemaname、tablename|Table|regclass|
|Lock|dbms_stats.lock_column_stats          |relname、attname<br>Or<br>schemaname、tablename、attname|列|regclass|
|Unlock|dbms_stats.unlock_database_stats  |(Without)|Database|regclass|
|Unlock|dbms_stats.unlock_schema_stats    |schemaname|Schema|regclass|
|Unlock|dbms_stats.unlock_table_stats     |relname<br>Or<br>schemaname、tablename|Table|regclass|
|Unlock|dbms_stats.unlock_column_stats    |relname、attname<br>Or<br>schemaname、tablename、attname|列|regclass|
|Import|dbms_stats.import_database_stats  |src|Database|void|
|Import|dbms_stats.import_schema_stats    |schemaname、src|Schema|void|
|Import|dbms_stats.import_table_stats     |relname、src<br>Or<br>schemaname、tablename、src|Table|void|
|Import|dbms_stats.import_column_stats|relname、attname、src<br>Or<br>schemaname、tablename、attname、src|列|void|
|Purge    |dbms_stats.purge_stats|backup_id、force|Backup|dbms_stats.backup_history|
|Cleanup|dbms_stats.clean_up_stats|(Without)|Database|text|

The arguments that are used in each function is as follows.


|Argument   |Data Type |Description  |
|:----------|:---------|:------------|
|schemaname |text |The schema name to be processed.|
|relname |regclass |This is the table name to be processed. However, It will be in the form of (schema name).(Table name).|
|tablename |text |This is the table name to be processed.|
|attname |text |This is the column name to be processed.|
|comment |text |comment to identify the backup.。|
|as_of_timestamp |timestamptz |Is the timestamp when you want to restore to. Restore the latest Backup data before the timestamp. If the Backup does not exist, it does not statistics value. |
|src |text |The absolute path of the file to be imported.|
|backup_id |bigint |It is a backup ID to be purge and restore. It restore statistical information with matching ID passed in restore function. It Purge statistic with matching ID passed to purge function. |
|force |bool |When you purge, it is a variable that determines whether to forcibly remove the backup. If true, delete all Backup target range. If false, print warning message Database Backup data exists outside the target range. Default value is false. |

Statistics export feature is also implemented in SQL file.
The meaning of each SQL file as follows. Furthermore, the default output file name is export_stats.dmp. 

|File Name  |Statistics Target |Remark      |
|:----------|:-----------------|:-----------|
|export_effective_stats.<PG ver>.sql.sample |Current Statistics planner is referring. |-|
|export_plain_stats-<PG ver>.sql.sample |Only for original statistics |it can be used even pg_dbms_stats not installed|

## Table

pg_dbms_stats contains the following table.


### dbms_stats.backup_history

|Column Name |Data Type |Description |
|:-----------|:---------|:-----------|
|id |int8 |It is a backup ID, assigned at the time of the backup.|
|time |timestamptz |The time stamp at the time of backup.|
|unit |char(1) |Backup object.。<br>d:Database、s:Schema、t:Table、c:Column|
|comment |text |It is a comment that you specified at the time of backup.|


## View

pg_dbms_stats includes following view.


|View Name |Description  |
|:---------|:------------|
|dbms_stats.relation_stats_effective |Statistic for each table object currently planner referring. It corresponds to the PostgreSQL's pg_class catalog.|
|dbms_stats.column_stats_effective|Statistic for each column, currently planner referring. It corresponds to the PostgreSQL's pg_statistic catalog.|
|dbms_stats.stats |Display the statistic for all column, planner is referring. It corresponds to the PostgreSQL's pg_stat catalog.|


## Related Item

[psql](http://www.postgresql.jp/document/current/html/app-psql.html),
[vacuumdb](http://www.postgresql.jp/document/current/html/app-vacuumdb.html)

------------------------------------------------------------------------

Copyright (c) 2009-2022, NIPPON TELEGRAPH AND TELEPHONE CORPORATION
