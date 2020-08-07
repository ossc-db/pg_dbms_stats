# SPEC file for pg_dbms_stats95
# Copyright(C) 2012-2018 NIPPON TELEGRAPH AND TELEPHONE CORPORATION

%define _pgdir   /usr/pgsql-9.5
%define _bindir  %{_pgdir}/bin
%define _libdir  %{_pgdir}/lib
%define _datadir %{_pgdir}/share
%define _docdir  /usr/share/doc/pgsql
%if "%(echo ${MAKE_ROOT})" != ""
  %define _rpmdir %(echo ${MAKE_ROOT})/RPMS
  %define _sourcedir %(echo ${MAKE_ROOT})
%endif

## Set general information for pg_dbms_stats.
Summary:    Plan Stabilizer for PostgreSQL 9.5
Name:       pg_dbms_stats95
Version:    1.3.11
Release:    1%{?dist}
License:    BSD
Group:      Applications/Databases
Source:     %{name}-%{version}.tar.gz
URL:        https://osdn.net/projects/pgdbmsstats/
BuildRoot:  %{buildroot}
Vendor:     NIPPON TELEGRAPH AND TELEPHONE CORPORATION

## postgresql-devel package required
BuildRequires:  postgresql95-devel
Requires:  postgresql95-libs

## Description for "pg_dbms_stats"
%description
pg_dbms_stats disguises database statistics with a prevously taken
snapshot so that the planner won't change its behavior even after
ANALYZE updates the statistics.

pg_dbms_stats also provides following features:
  - backup multiple generations of planner statistics to reuse plans afterwards
  - import planner statistics from another system for tuning or testing.

Note that this package is available for only PostgreSQL 9.5.

## pre work for build pg_dbms_stats
%prep
PATH=/usr/pgsql-9.5/bin:$PATH
if [ ! -d %{_rpmdir} ]; then mkdir -p %{_rpmdir}; fi
%setup -q

## Set variables for build environment
%build
PATH=/usr/pgsql-9.5/bin:$PATH
make USE_PGXS=1 %{?_smp_mflags}

## Set variables for install
%install
rm -rf %{buildroot}
install -d %{buildroot}%{_libdir}
install -m 755 pg_dbms_stats.so %{buildroot}%{_libdir}/pg_dbms_stats.so
install -d %{buildroot}%{_datadir}/extension
install -m 644 pg_dbms_stats--1.3.11.sql %{buildroot}%{_datadir}/extension/pg_dbms_stats--1.3.11.sql
install -m 644 pg_dbms_stats--1.3.7--1.3.9.sql %{buildroot}%{_datadir}/extension/pg_dbms_stats--1.3.7--1.3.9.sql
install -m 644 pg_dbms_stats--1.3.9--1.3.10.sql %{buildroot}%{_datadir}/extension/pg_dbms_stats--1.3.9--1.3.10.sql
install -m 644 pg_dbms_stats--1.3.10--1.3.11.sql %{buildroot}%{_datadir}/extension/pg_dbms_stats--1.3.10--1.3.11.sql
install -m 644 pg_dbms_stats.control %{buildroot}%{_datadir}/extension/pg_dbms_stats.control
install -d %{buildroot}%{_docdir}/extension
install -m 644 doc/export_effective_stats-9.5.sql.sample %{buildroot}%{_docdir}/extension/export_effective_stats-9.5.sql.sample
install -m 644 doc/export_plain_stats-9.5.sql.sample %{buildroot}%{_docdir}/extension/export_plain_stats-9.5.sql.sample

%clean
rm -rf %{buildroot}

%files
%defattr(0755,root,root)
%{_libdir}/pg_dbms_stats.so
%defattr(0644,root,root)
%{_datadir}/extension/pg_dbms_stats--1.3.11.sql
%{_datadir}/extension/pg_dbms_stats--1.3.7--1.3.9.sql
%{_datadir}/extension/pg_dbms_stats--1.3.9--1.3.10.sql
%{_datadir}/extension/pg_dbms_stats--1.3.10--1.3.11.sql
%{_datadir}/extension/pg_dbms_stats.control
%{_docdir}/extension/export_effective_stats-9.5.sql.sample
%{_docdir}/extension/export_plain_stats-9.5.sql.sample

# History of pg_dbms_stats.
%changelog
* Wed Sep 26 2018 Kyotaro Horiguchi
- Update to 1.3.11. Bug fix.
* Thu Apr 05 2018 Kyotaro Horiguchi
- Update to 1.3.10. Bug fix.
* Mon Nov 13 2017 Kyotaro Horiguchi
- Update to 1.3.9. Bug fixed.
* Fri Mar 25 2016 Kyotaro Horiguchi
- pg_dbms_stats95 v1.3.7 release


