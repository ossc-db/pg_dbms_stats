# pg_dbms_stats/Makefile

MODULE_big = pg_dbms_stats
OBJS = pg_dbms_stats.o dump.o import.o
DBMSSTATSVER=1.3.2

ifdef UNIT_TEST
PG_CPPFLAGS = -DUNIT_TEST
endif

LAST_LIBPATH=$(shell echo $(LD_LIBRARY_PATH) | sed -e "s/^.*;//")
CHECKING=$(shell echo $(LAST_LIBPATH)| grep './tmp_check/install/' | wc -l)

EXTENSION = pg_dbms_stats
DATA = pg_dbms_stats--1.3.2.sql pg_dbms_stats--1.0--1.3.2.sql

REGRESS = init-common ut_fdw_init init-$(MAJORVERSION) ut-common \
		  ut-$(MAJORVERSION)  ut_imp_exp-$(MAJORVERSION)

REGRESS_OPTS = --encoding=UTF8 --temp-config=regress.conf --extra-install=contrib/file_fdw

DOCS = export_effective_stats.sql.sample export_plain_stats.sql.sample

STARBALL = pg_dbms_stats-$(DBMSSTATSVER).tar.gz
STARBALL92 = pg_dbms_stats92-$(DBMSSTATSVER).tar.gz
STARBALL93 = pg_dbms_stats93-$(DBMSSTATSVER).tar.gz
STARBALLS = $(STARBALL) $(STARBALL93) $(STARBALL92)

EXTRA_CLEAN = sql/ut_anyarray-*.sql expected/ut_anyarray-*.out \
	sql/ut_imp_exp-*.sql expected/ut_imp_exp-*.out \
	sql/ut_fdw_init-*.sql expected/ut_fdw_init-*.out \
	pg_dbms_stats--1.0--1.3.2.sql export_plain_stats.sql.sample \
	export_effective_stats.sql.sample \
	export_stats.dmp ut-fdw.csv $(DATA) $(STARBALLS) RPMS \
	*~

ifdef USE_PGXS
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
else
subdir = contrib/pg_dbms_stats
top_builddir = ../..
include $(top_builddir)/src/Makefile.global
include $(top_srcdir)/contrib/contrib-global.mk
endif

ifeq "$(MAJORVERSION)" "9.4"
MAJORVERSION=9.3
endif

TARSOURCES = Makefile *.c  *.h pg_dbms_stats--*-9.*.sql pg_dbms_stats.control \
	export_*_stats-9.*.sql.sample COPYRIGHT \
	doc/* expected/*.out sql/*.sql input/*.source input/*.csv \
	output/*.source SPECS/*.spec

RPMS93 = RPMS/pg_dbms_stats93-$(DBMSSTATSVER)-1.el6.x86_64.rpm \
	 RPMS/pg_dbms_stats93-debuginfo-$(DBMSSTATSVER)-1.el6.x86_64.rpm 
RPMS92 = RPMS/pg_dbms_stats92-$(DBMSSTATSVER)-1.el6.x86_64.rpm \
	 RPMS/pg_dbms_stats92-debuginfo-$(DBMSSTATSVER)-1.el6.x86_64.rpm 

all: $(DATA) $(DOCS)

rpms: $(RPMS93)  $(RPMS92)

sourcetar: $(STARBALL)

$(DATA): %.sql: %-$(MAJORVERSION).sql											
	cp $< $@

$(DOCS): %.sql.sample: %-$(MAJORVERSION).sql.sample
	cp $< $@

$(STARBALLS): $(TARSOURCES)
	if [ -h $(subst .tar.gz,,$@) ]; then rm $(subst .tar.gz,,$@); fi
	if [ -e $(subst .tar.gz,,$@) ]; then \
	  echo "$(subst .tar.gz,,$@) is not a symlink. Stop."; \
	  exit 1; \
	fi
	ln -s . $(subst .tar.gz,,$@)
	tar -chzf $@ $(addprefix $(subst .tar.gz,,$@)/, $^)
	rm $(subst .tar.gz,,$@)

$(RPMS93): $(STARBALL93)
	export MAKE_ROOT=`pwd`
	rpmbuild -bb SPECS/pg_dbms_stats93.spec

$(RPMS92): $(STARBALL92)
	export MAKE_ROOT=`pwd`
	rpmbuild -bb SPECS/pg_dbms_stats92.spec