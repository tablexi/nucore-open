alter profile default limit password_life_time unlimited;


-- create tablespace BC_NUCORE
--     DATAFILE 'bc_nucore.dat'
--     SIZE 100M
--     AUTOEXTEND ON;

CREATE USER nucore_open_development
    IDENTIFIED BY password
    DEFAULT TABLESPACE users
    TEMPORARY TABLESPACE temp;

GRANT connect, resource TO nucore_open_development;
GRANT UNLIMITED TABLESPACE TO nucore_open_development;

CREATE USER nucore_open_test
    IDENTIFIED BY password
    DEFAULT TABLESPACE users
    TEMPORARY TABLESPACE temp;

GRANT connect, resource TO nucore_open_test;
GRANT UNLIMITED TABLESPACE TO nucore_open_test;
