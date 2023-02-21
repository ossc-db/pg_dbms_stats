# pg_dbms_stats/Makefile

DBMSSTATSVER = 15.0
PGVERS = 15

MODULE_big = pg_dbms_stats
OBJS = pg_dbms_stats.o dump.o import.o
DOCDIR = doc

ifdef UNIT_TEST
PG_CPPFLAGS = -DUNIT_TEST
endif

LAST_LIBPATH=$(shell echo $(LD_LIBRARY_PATH) | sed -e "s/^.*;//")
CHECKING=$(shell echo $(LAST_LIBPATH)| grep './tmp_check/install/' | wc -l)
EXTENSION = pg_dbms_stats

REGRESS = init-common ut_fdw_init init ut-common ut ut_imp_exp
EXTRA_INSTALL = contrib/file_fdw

REGRESS_OPTS = --encoding=UTF8 --temp-config=regress.conf

# Pick up only the install scripts needed for the PG version.
DATA = pg_dbms_stats--$(DBMSSTATSVER).sql

DOCS = $(DOCDIR)/export_effective_stats-$(MAJORVERSION).sql.sample \
	$(DOCDIR)/export_plain_stats-$(MAJORVERSION).sql.sample

# Source tarballs required for rpmbuild
STARBALL = pg_dbms_stats-$(DBMSSTATSVER).tar.gz
STARBALLS = $(STARBALL) $(foreach v,$(PGVERS),pg_dbms_stats$(v).tar.gz)

# Generate RPM target names for all target PG versions
RPMS = $(foreach v,$(PGVERS),rpm$(v))

EXTRA_CLEAN = sql/ut_anyarray-*.sql expected/ut_anyarray-*.out \
	export_stats.dmp ut-fdw.csv $(STARBALLS) RPMS/*/* \
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

TARSOURCES = Makefile *.c  *.h \
	pg_dbms_stats.control COPYRIGHT ChangeLog ChangeLog.ja \
	README.installcheck regress.conf $(DATA) \
	doc/* expected/init-*.out expected/ut-*.out \
	sql/init-*.sql sql/ut-*.sql \
	input/*.source input/*.csv output/*.source SPECS/*.spec

LDFLAGS+=-Wl,--build-id

all: $(DOCS)

rpms: $(RPMS)

sourcetar: $(STARBALL)

# Source tar balls are the same for all target PG versions.
# This is because rpmbuild requires a tar ball with the same base name
# with target rpm file.
$(STARBALLS): $(TARSOURCES)
	if [ -h $(subst .tar.gz,,$@) ]; then rm $(subst .tar.gz,,$@); fi
	if [ -e $(subst .tar.gz,,$@) ]; then \
	  echo "$(subst .tar.gz,,$@) is not a symlink. Stop."; \
	  exit 1; \
	fi
	ln -s . $(subst .tar.gz,,$@)
	tar -chzf $@ $(addprefix $(subst .tar.gz,,$@)/, $^)
	rm $(subst .tar.gz,,$@)

$(RPMS): rpm% : SPECS/pg_dbms_stats.spec pg_dbms_stats-$(DBMSSTATSVER).tar.gz
	MAKE_ROOT=`pwd` rpmbuild -bb $<

