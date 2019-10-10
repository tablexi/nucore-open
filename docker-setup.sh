#!/bin/sh

cp --no-clobber config/database.yml.mysql.template config/database.yml
cp --no-clobber config/secrets.yml.template config/secrets.yml

docker-compose run app bundle install
docker-compose run app bundle exec rake secret
echo "Add this to secrets.yml as your secret_key_base"
