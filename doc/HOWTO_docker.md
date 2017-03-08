# Using Docker for Development

## Install Docker

* Download and install Docker https://docs.docker.com/engine/getstarted/step_one/

## Running Oracle Standalone

If you want to run the Oracle database in Docker, but the app itself in your native
environment, please follow [the instructions for how to install the Oracle drivers](HOWTO_oracle.txt) first, and then proceed from here.

Make sure you have the `activerecord-oracle_enhanced-adapter` and `ruby-oci8` gems
enabled.

- `cp config/database.yml.oracle.template config/database.yml`

```
docker run -d -p 1521:1521 --name nucore_db wnameless/oracle-xe-11g
# wait, it sometimes takes a few minutes to come up
# "ORA-01033: ORACLE initialization or shutdown in progress" means wait.
docker/oracle/setup.sh
# demo:seed is optional
rake demo:seed
```

Next time you want to start the server,

```
docker start nucore_db
```
