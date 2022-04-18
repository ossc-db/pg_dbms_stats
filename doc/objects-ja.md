# pg_dbms_stats 14.0

[pg_dms_stats](pg_dbms_stats-ja.md) -> [Appendix A. オブジェクト一覧](objects-ja.md)

<div class="index">

1.  [関数](#関数)
2.  [テーブル](#テーブル)
3.  [ビュー](#ビュー)

</div>

## 関数

pg_dbms_stats は下記の関数を含みます。
各関数の意味は以下の通りです。


|機能         |関数                            |引数 |オブジェクト単位|戻り値|
|:-----------|:--------------------------------|:----|:---------------|:-----|
|バックアップ|dbms_stats.backup_database_stats|comment|データベース|int8|
|バックアップ|dbms_stats.backup_schema_stats  |schemaname、comment|スキーマ|int8|
|バックアップ|dbms_stats.backup_table_stats   |relname、comment<br>または<br>schemaname、tablename、comment|テーブル|int8|
|バックアップ|dbms_stats.backup_column_stats  |relname、attname、comment<br>または<br>schemaname、tablename、attname、comment|列|int8|
|リストア|dbms_stats.restore_database_stats   |timestamp|データベース|regclass|
|リストア|dbms_stats.restore_schema_stats     |schemaname、timestamp|スキーマ|regclass|
|リストア|dbms_stats.restore_table_stats      |relname、timestamp<br>または<br>schemaname、tablename、timestamp |テーブル|regclass|
|リストア|dbms_stats.restore_column_stats     |relname、attname、timestamp<br>または<br>schemaname、tablename、attname、timestamp|列|regclass|
|リストア|dbms_stats.restore_stats            |backup_id  |バックアップ|regclass|
|ロック|dbms_stats.lock_database_stats        |(なし)|データベース|regclass|
|ロック|dbms_stats.lock_schema_stats          |schemaname|スキーマ|regclass|
|ロック|dbms_stats.lock_table_stats           |relname<br>または<br>schemaname、tablename|テーブル|regclass|
|ロック|dbms_stats.lock_column_stats          |relname、attname<br>または<br>schemaname、tablename、attname|列|regclass|
|ロック解除|dbms_stats.unlock_database_stats  |(なし)|データベース|regclass|
|ロック解除|dbms_stats.unlock_schema_stats    |schemaname|スキーマ|regclass|
|ロック解除|dbms_stats.unlock_table_stats     |relname<br>または<br>schemaname、tablename|テーブル|regclass|
|ロック解除|dbms_stats.unlock_column_stats    |relname、attname<br>または<br>schemaname、tablename、attname|列|regclass|
|インポート|dbms_stats.import_database_stats  |src|データベース|void|
|インポート|dbms_stats.import_schema_stats    |schemaname、src|スキーマ|void|
|インポート|dbms_stats.import_table_stats     |relname、src<br>または<br>schemaname、tablename、src|テーブル|void|
|インポート|dbms_stats.import_column_stats|relname、attname、src<br>または<br>schemaname、tablename、attname、src|列|void|
|パージ    |dbms_stats.purge_stats|backup_id、force|バックアップ|dbms_stats.backup_history|
|クリーンアップ|dbms_stats.clean_up_stats|(なし)|データベース|text|

各関数で用いられている引数の意味は以下の通りです。


|引数       |データ型 |意味        |
|:----------|:--------|:-----------|
|schemaname |text |処理対象のスキーマ名です。|
|relname |regclass |処理対象のテーブル名です。ただし、(スキーマ名).(テーブル名) という形になります。|
|tablename |text |処理対象のテーブル名です。|
|attname |text |処理対象の列名です。|
|comment |text |バックアップを識別するためのコメントです。|
|as_of_timestamp |timestamptz |リストアしたいタイミングの基準になるタイムスタンプです。このタイムスタンプ以前で最新のバックアップデータをリストアします。該当するバックアップが存在しない場合、統計情報は現在プランナが見ている値から変更されません。|
|src |text |インポート対象のファイルの絶対パスです。|
|backup_id |bigint |リストアやパージの対象となるバックアップIDです。 リストアの場合、一致するバックアップIDのバックアップデータをリストアします。 パージの場合、一致するバックアップID以前のバックアップを削除します。|
|force |bool |パージするとき、バックアップを強制的に削除するかを決める変数です。 trueの場合、対象範囲のバックアップを全て削除します。 falseの場合、対象範囲外にデータベース単位のバックアップデータが存在しなければ、警告メッセージを出力して処理を中断します。 デフォルトはfalseです。|

また、統計情報のエクスポート機能は、SQLファイルで実装しています。
各SQLファイルの意味は以下の通りです。なお、出力ファイル名のデフォルトはexport_stats.dmpです。

|ファイル名 |対象統計情報|備考|
|:----------|:--------|:-----------|
|export_effective_stats.<PGバージョン>.sql.sample |プランナが見ている統計情報 |-|
|export_plain_stats-<PGバージョン>.sql.sample |真の統計情報のみ |pg_dbms_stats未インストールでも使用可能です|

## テーブル

pg_dbms_statsは以下のテーブルを含みます。各テーブルの意味は以下の通りです。

### dbms_stats.backup_history

|列名    |データ型|意味  |
|:-------|:-------|:-----|
|id |int8 |バックアップ時に付与されたバックアップIDです。|
|time |timestamptz |バックアップ時のタイムスタンプです。|
|unit |char(1) |バックアップ時のオブジェクト単位です。<br>d:データベース、s:スキーマ、t:テーブル、c:列|
|comment |text |バックアップ時に指定したコメントです。|



## ビュー

pg_dbms_stats は下記のビューを含みます。各ビューの意味は以下の通りです。


|ビュー名|意味|
|:-------|:---|
|dbms_stats.relation_stats_effective |プランナに見せるテーブルごとの統計情報を表示します。PostgreSQLのpg_classカタログに対応します。|
|dbms_stats.column_stats_effective|プランナに見せる列ごとの統計情報を表示します。PostgreSQLのpg_statisticカタログに対応します。|
|dbms_stats.stats |プランナに見せる列ごとの統計情報のうち、ユーザが読み取り可能なものを表示します。PostgreSQLのpg_statsビューに対応します。|


## 関連項目

[psql](http://www.postgresql.jp/document/current/html/app-psql.html),
[vacuumdb](http://www.postgresql.jp/document/current/html/app-vacuumdb.html)

------------------------------------------------------------------------

Copyright (c) 2009-2022, NIPPON TELEGRAPH AND TELEPHONE CORPORATION
