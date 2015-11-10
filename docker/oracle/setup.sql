CREATE USER nucore_development
    IDENTIFIED BY password
    DEFAULT TABLESPACE users
    TEMPORARY TABLESPACE temp;

GRANT connect, resource TO nucore_development;

CREATE USER nucore_test
    IDENTIFIED BY password
    DEFAULT TABLESPACE users
    TEMPORARY TABLESPACE temp;

GRANT connect, resource TO nucore_test;

create tablespace BC_NUCORE
    DATAFILE 'bc_nucore.dat'
    SIZE 100M
    AUTOEXTEND ON;
