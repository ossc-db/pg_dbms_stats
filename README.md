# pg_dbms_stats

pg_dbms_statsは、PostgreSQLが実行計画作成に利用する統計情報を管理し、間接的に実行計画を制御できるようにします。

特定の状態の統計情報を保存しておき、実行計画作成時に最新の統計情報ではなく保存しておいた統計情報を見せることができます。 これにより、運用中に実行計画が急に変化して、クエリの性能が不安定化するリスクを抑えることが可能です。

[日本語のマニュアルはこちら](/doc/pg_dbms_stats-ja.md)

[English version here](/doc/pg_dbms_stats-en.md)

-----
Copyright (c) 2012-2022, NIPPON TELEGRAPH AND TELEPHONE CORPORATION
