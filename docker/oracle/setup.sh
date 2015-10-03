#!/bin/sh

echo "copying database.yml"
cp config/database.yml.oracle.template /app/config/database.yml

echo "Creating Databases"
ruby docker/oracle/create_databases.rb

echo "Loading development schema"
bundle exec rake db:oracle_drop
bundle exec rake db:schema:load

echo "Loading test schema"
export RAILS_ENV=test
bundle exec rake db:oracle_drop
bundle exec rake db:schema:load

