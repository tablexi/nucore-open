#!/bin/sh

cp config/database.yml.mysql.docker config/database.yml
cp config/secrets.yml.template config/secrets.yml

echo "Please copy your github ssh key to ssh/id_rsa so that we can download private github repos."
