/*
 * pg_dbms_stats.h
 *
 * Copyright (c) 2009-2018, NIPPON TELEGRAPH AND TELEPHONE CORPORATION
 * Portions Copyright (c) 1996-2013, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 */

#ifndef PG_DBMS_STATS_H
#define PG_DBMS_STATS_H

bool dbms_stats_is_system_schema_internal(char *schema_name);
bool dbms_stats_is_system_catalog_internal(Oid regclass, LOCKMODE lockmode);

#endif /* PG_DBMS_STATS_H */
