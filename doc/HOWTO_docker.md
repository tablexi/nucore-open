# Using Docker for Development

## Install Docker

Assuming you are on a Mac:

* Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
* Follow the instructions at http://docs.docker.com/mac/step_one/

## Set up `dockerhost`

Edit your `/etc/hosts` file so `dockerhost` points to the Docker host IP address.
You should see this in the Docker startup. If you do this, you will be able to access
the web application via http://dockerhost:3000

## Databases

### MySQL

The Docker configuration is designed to work on top of MySQL 5.6 by default. Nothing
should need to change.

```
docker-compose build
docker-compose run web rake db:create db:schema:load db:seed
docker-compose up -d
# Optional
docker-compose run web rake demo:seed
```

### Oracle

* This runs Oracle 11g XE, which is the free version of Oracle. Your production
  infrastructure might run Oracle 12c, so do not rely on this for 100% coverage.

1. Uncomment the `oracle` references in `docker-compose.yml` and comment/delete the
mysql references.

2. Download the [Oracle Instant Client libraries](http://www.oracle.com/technetwork/database/features/instant-client/index-097480.html)
    * Basic
    * SQL Plus
    * SDK
3. Copy the `.deb` files into the `tmp` directory

```
docker-compose build
docker-compose run web docker/oracle/setup.sh
docker-compose up -d
#Optional
docker-compose run web rake demo:seed

```
TODO

## LDAP

TODO
