# pg_dbms_stats/Makefile

MODULE_big = pg_dbms_stats
OBJS = pg_dbms_stats.o dump.o import.o

ifdef UNIT_TEST
PG_CPPFLAGS = -DUNIT_TEST
endif

EXTENSION = pg_dbms_stats
DATA = pg_dbms_stats--1.0.sql

REGRESS = init-common init-$(MAJORVERSION) ut-common ut-$(MAJORVERSION) \
		  ut_imp_exp-$(MAJORVERSION)

REGRESS_OPTS = --encoding=UTF8

DOCS = export_effective_stats-$(MAJORVERSION).sql.sample \
	   export_plain_stats-$(MAJORVERSION).sql.sample

EXTRA_CLEAN = sql/ut_anyarray-*.sql expected/ut_anyarray-*.out \
			  sql/ut_imp_exp-*.sql expected/ut_imp_exp-*.out \
			  export_stats.dmp $(DATA)

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

all: $(DATA) $(DOCS)

$(DATA): %.sql: %-$(MAJORVERSION).sql
	cp $< $@

