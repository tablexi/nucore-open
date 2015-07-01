#!/bin/sh

table_names() {
  grep '^\s*create_table "' schema.rb |
  cut -d'"' -f2 |
  tr '[:lower:]' '[:upper:]'
}

(echo SCHEMA_MIGRATIONS; table_names) |
while read table_name; do
  echo "DROP SEQUENCE ${table_name}_SEQ;"
  echo "DROP TABLE ${table_name} CASCADE CONSTRAINTS;"
done
