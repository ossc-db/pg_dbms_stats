# pg_dbms_stats/Makefile

MODULE_big = pg_dbms_stats
OBJS = pg_dbms_stats.o dump.o import.o
DBMSSTATSVER = 1.3.4
DOCDIR = doc
EXTDIR = ext_scripts

ifdef UNIT_TEST
PG_CPPFLAGS = -DUNIT_TEST
endif

LAST_LIBPATH=$(shell echo $(LD_LIBRARY_PATH) | sed -e "s/^.*;//")
CHECKING=$(shell echo $(LAST_LIBPATH)| grep './tmp_check/install/' | wc -l)

EXTENSION = pg_dbms_stats
DATA = pg_dbms_stats--1.3.4.sql pg_dbms_stats--1.0--1.3.2.sql pg_dbms_stats--1.3.2--1.3.3.sql pg_dbms_stats--1.3.3--1.3.4.sql

REGRESS = init-common ut_fdw_init init-$(MAJORVERSION) ut-common \
		  ut-$(MAJORVERSION)  ut_imp_exp-$(MAJORVERSION)

REGRESS_OPTS = --encoding=UTF8 --temp-config=regress.conf --extra-install=contrib/file_fdw

DOCS = $(DOCDIR)/export_effective_stats-$(MAJORVERSION).sql.sample \
	$(DOCDIR)/export_plain_stats-$(MAJORVERSION).sql.sample

STARBALL = pg_dbms_stats-$(DBMSSTATSVER).tar.gz
STARBALL94 = pg_dbms_stats94-$(DBMSSTATSVER).tar.gz
STARBALL93 = pg_dbms_stats93-$(DBMSSTATSVER).tar.gz
STARBALL92 = pg_dbms_stats92-$(DBMSSTATSVER).tar.gz
STARBALL91 = pg_dbms_stats91-$(DBMSSTATSVER).tar.gz
STARBALLS = $(STARBALL) $(STARBALL94) $(STARBALL93) $(STARBALL92) $(STARBALL91)

EXTRA_CLEAN = sql/ut_anyarray-*.sql expected/ut_anyarray-*.out \
	sql/ut_imp_exp-*.sql expected/ut_imp_exp-*.out \
	sql/ut_fdw_init.sql expected/ut_fdw_init.out \
	export_stats.dmp ut-fdw.csv $(DATA) $(STARBALLS) RPMS/*/* \
	*~

ifndef USE_PGXS
ifeq ($(wildcard ../../contrib/contrib-global.mk),)
	USE_PGXS=1
endif
endif

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
ifeq "$(MAJORVERSION)" "9.5"
MAJORVERSION=9.3
endif

TARSOURCES = Makefile *.c  *.h \
	$(EXTDIR)/pg_dbms_stats--*-9.*.sql \
	pg_dbms_stats.control COPYRIGHT ChangeLog ChangeLog.ja \
	README.installcheck regress.conf \
	doc/* expected/init-*.out expected/ut-*.out \
	sql/init-*.sql sql/ut-*.sql \
	input/*.source input/*.csv output/*.source SPECS/*.spec

all: $(DATA) $(DOCS)

rpms: rpm93 rpm92 rpm91

sourcetar: $(STARBALL)

$(DATA): %.sql: $(EXTDIR)/%-$(MAJORVERSION).sql
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

rpm94: $(STARBALL94)
	MAKE_ROOT=`pwd` rpmbuild -bb SPECS/pg_dbms_stats94.spec

rpm93: $(STARBALL93)
	MAKE_ROOT=`pwd` rpmbuild -bb SPECS/pg_dbms_stats93.spec

rpm92: $(STARBALL92)
	MAKE_ROOT=`pwd` rpmbuild -bb SPECS/pg_dbms_stats92.spec

rpm91: $(STARBALL91)
	MAKE_ROOT=`pwd` rpmbuild -bb SPECS/pg_dbms_stats91.spec
