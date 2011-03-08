cat -n schema.oracle.sql \
| sort -rn \
| grep 'CREATE ' \
| perl -ne '/CREATE (SEQUENCE|TABLE) (\w+)/; print uc $1 eq "SEQUENCE" ? "DROP $1 $2;\n" : "DROP $1 $2 CASCADE CONSTRAINTS;\n"';
