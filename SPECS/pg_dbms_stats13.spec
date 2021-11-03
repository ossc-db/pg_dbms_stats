# SPEC file for pg_dbms_stats13
# Copyright(c) 2012-2021, NIPPON TELEGRAPH AND TELEPHONE CORPORATION

%define _pgdir   /usr/pgsql-13
%define _bindir  %{_pgdir}/bin
%define _libdir  %{_pgdir}/lib
%define _datadir %{_pgdir}/share
%define _docdir  %{_pgdir}/doc
%define _bcdir %{_libdir}/bitcode

%if "%(echo ${MAKE_ROOT})" != ""
  %define _rpmdir %(echo ${MAKE_ROOT})/RPMS
  %define _sourcedir %(echo ${MAKE_ROOT})
%endif

## Set general information for pg_dbms_stats.
Summary:    Plan Stabilizer for PostgreSQL 13
Name:       pg_dbms_stats13
Version:    1.5.0
Release:    1%{?dist}
License:    BSD
Group:      Applications/Databases
Source:     %{name}-%{version}.tar.gz
URL:        https://osdn.net/projects/pgdbmsstats/
BuildRoot:  %{buildroot}
Vendor:     NIPPON TELEGRAPH AND TELEPHONE CORPORATION

## postgresql-devel package required
#BuildRequires:  postgresql13-devel
#Requires:  postgresql13-server

## Description for "pg_dbms_stats"
%description
pg_dbms_stats disguises database statistics with a prevously taken
snapshot so that the planner won't change its behavior even after
ANALYZE updates the statistics.

pg_dbms_stats also provides following features:
  - backup multiple generations of planner statistics to reuse plans afterwards
  - import planner statistics from another system for tuning or testing.

Note that this package is available for only PostgreSQL 13.

%package llvmjit
Requires: postgresql13-server, postgresql13-llvmjit
Requires: pg_hint_plan13 = 1.5.0
Summary:  Just-in-time compilation support for pg_hint_plan11

%description llvmjit
Just-in-time compilation support for pg_hint_plan11

## pre work for build pg_dbms_stats
%prep
PATH=/usr/pgsql-13/bin:$PATH
if [ ! -d %{_rpmdir} ]; then mkdir -p %{_rpmdir}; fi
%setup -q

## Set variables for build environment
%build
PATH=/usr/pgsql-13/bin:$PATH
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
%{_datadir}/extension/pg_dbms_stats--%{version}.sql
%{_datadir}/extension/pg_dbms_stats.control
%{_docdir}/extension/export_effective_stats-13.sql.sample
%{_docdir}/extension/export_plain_stats-13.sql.sample

%files llvmjit
%{_bcdir}

# History of pg_dbms_stats.
%changelog
* Tue Oct 27 2020 Kyotaro Horiguchi
- Update to 1.5.0. Support PG13.
* Thu Aug 6 2020 Kyotaro Horiguchi
- Update to 1.4.0. Support PG12.
* Wed Sep 26 2018 Kyotaro Horiguchi
- Update to 1.3.11. Bug fix.
* Thu Apr 05 2018 Kyotaro Horiguchi
- Update to 1.3.10. Bug fix.
* Mon Nov 13 2017 Kyotaro Horiguchi
- Update to 1.3.9. Bug fixed.
* Tue Oct 10 2017 Kyotaro Horiguchi
- pg_dbms_stats10 v1.3.8 release

