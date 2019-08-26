# SPEC file for pg_dbms_stats11
# Copyright(C) 2012-2019 NIPPON TELEGRAPH AND TELEPHONE CORPORATION

%define _pgdir   /usr/pgsql-11
%define _bindir  %{_pgdir}/bin
%define _libdir  %{_pgdir}/lib
%define _datadir %{_pgdir}/share
%define _bcdir %{_libdir}/bitcode
%define _mybcdir %{_bcdir}/pg_dbms_stats

%define _docdir  %{_pgdir}/doc
%if "%(echo ${MAKE_ROOT})" != ""
  %define _rpmdir %(echo ${MAKE_ROOT})/RPMS
  %define _sourcedir %(echo ${MAKE_ROOT})
%endif

## Set general information for pg_dbms_stats.
Summary:    Plan Stabilizer for PostgreSQL 11
Name:       pg_dbms_stats11
Version:    1.3.11
Release:    1%{?dist}
License:    BSD
Group:      Applications/Databases
Source:     %{name}-%{version}.tar.gz
URL:        http://sourceforge.jp/projects/pgdbmsstats/
BuildRoot:  %{buildroot}
Vendor:     NIPPON TELEGRAPH AND TELEPHONE CORPORATION

## postgresql-devel package required
BuildRequires:  postgresql11
Requires:  postgresql11-libs

## Description for "pg_dbms_stats"
%description
pg_dbms_stats disguises database statistics with a prevously taken
snapshot so that the planner won't change its behavior even after
ANALYZE updates the statistics.

pg_dbms_stats also provides following features:
  - backup multiple generations of planner statistics to reuse plans afterwards
  - import planner statistics from another system for tuning or testing.

Note that this package is available for only PostgreSQL 11.

%package llvmjit
Requires: postgresql11-server, postgresql11-llvmjit
Requires: pg_dbms_stats11 = 1.3.11
Summary:  Just-in-time compilation support for pg_dbms_stats11

%description llvmjit
Just-in-time compilation support for pg_dbms_stats11

## pre work for build pg_dbms_stats
%prep
PATH=/usr/pgsql-11/bin:$PATH
if [ ! -d %{_rpmdir} ]; then mkdir -p %{_rpmdir}; fi
%setup -q

## Set variables for build environment
%build
PATH=/usr/pgsql-11/bin:$PATH
make USE_PGXS=1 %{?_smp_mflags}

## Set variables for install
%install
rm -rf %{buildroot}
make install DESTDIR=%{buildroot}

%clean
rm -rf %{buildroot}

%files
%defattr(0755,root,root)
%{_libdir}/pg_dbms_stats.so
%defattr(0644,root,root)
%{_datadir}/extension/pg_dbms_stats--1.3.11.sql
%{_datadir}/extension/pg_dbms_stats.control
%{_docdir}/extension/export_effective_stats-11.sql.sample
%{_docdir}/extension/export_plain_stats-11.sql.sample

%files llvmjit
%{_bcdir}

# History of pg_dbms_stats.
%changelog
* Mon Aug 26 2019 Kyotaro Horiguchi
- Relasee for PG11
