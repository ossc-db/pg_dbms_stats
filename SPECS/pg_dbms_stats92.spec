# SPEC file for pg_dbms_stats
# Copyright(C) 2012-2014 NIPPON TELEGRAPH AND TELEPHONE CORPORATION

%define _pgdir   /usr/pgsql-9.2
%define _bindir  %{_pgdir}/bin
%define _libdir  %{_pgdir}/lib
%define _datadir %{_pgdir}/share
%define _docdir  /usr/share/doc/pgsql

## Set general information for pg_dbms_stats.
Summary:    Plan Stabilizer for PostgreSQL 9.2
Name:       pg_dbms_stats92
Version:    1.3.1
Release:    1%{?dist}
License:    BSD
Group:      Applications/Databases
Source0:    %{name}-%{version}.tar.gz
#URL:        http://example.com/pg_dbms_stats/
BuildRoot:  %{_tmppath}/%{name}-%{version}-%{release}-%(%{__id_u} -n)
Vendor:     NIPPON TELEGRAPH AND TELEPHONE CORPORATION

## We use postgresql-devel package
BuildRequires:  postgresql92-devel
Requires:  postgresql92-libs

## Description for "pg_dbms_stats"
%description
pg_dbms_stats provides capability to replace planner's statistics with snapshot
taken at arbitrary timing, so that planner generates stable plans even if
ANALYZE is invoked after changes of data.

pg_dbms_stats also provides following features:
  - backup multiple generations of planner statistics to reuse plans after
  - import planner statistics from another system for tuning an testing

Note that this package is available for only PostgreSQL 9.2.

## pre work for build pg_dbms_stats
%prep
%setup -q

## Set variables for build environment
%build
make %{?_smp_mflags}

## Set variables for install
%install
rm -rf %{buildroot}
install -d %{buildroot}%{_libdir}
install -m 755 pg_dbms_stats.so %{buildroot}%{_libdir}/pg_dbms_stats.so
install -d %{buildroot}%{_datadir}/extension
install -m 644 pg_dbms_stats--1.0.sql %{buildroot}%{_datadir}/extension/pg_dbms_stats--1.0.sql
install -m 644 pg_dbms_stats.control %{buildroot}%{_datadir}/extension/pg_dbms_stats.control
install -d %{buildroot}%{_docdir}/extension
install -m 644 export_effective_stats-9.2.sql.sample %{buildroot}%{_docdir}/extension/export_effective_stats-9.2.sql.sample
install -m 644 export_plain_stats-9.2.sql.sample %{buildroot}%{_docdir}/extension/export_plain_stats-9.2.sql.sample

%clean
rm -rf %{buildroot}

%files
%defattr(0755,root,root)
%{_libdir}/pg_dbms_stats.so
%defattr(0644,root,root)
%{_datadir}/extension/pg_dbms_stats--1.0.sql
%{_datadir}/extension/pg_dbms_stats.control
%{_docdir}/extension/export_effective_stats-9.2.sql.sample
%{_docdir}/extension/export_plain_stats-9.2.sql.sample

# History of pg_dbms_stats.
%changelog
* Wed Nov 06 2013 Takashi Suzuki
- Update to 1.3.1
* Wed Sep 05 2012 Shigeru Hanada
- Initial cut for 1.0.0

