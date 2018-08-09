# Running Oracle in Development

Follow these instructions to set up the Oracle database to run in Docker, but the app itself in your native environment.

## Setting up the Oracle Server with Docker

##### Install Docker

* Download Docker for Mac from: `https://docs.docker.com/docker-for-mac/install/#download-docker-for-mac`

* Install into `/Applications`

* Start the oracle container:

```
mkdir $HOME/oracle_data
docker run -p 1521:1521 --name nucore_db -v $HOME/oracle_data:/u01/app/oracle sath89/oracle-12c
# This will take several minutes as the database initializes.
# Wait for "Database ready to use. Enjoy! ;)"
```

`$HOME/oracle_data` is just a recommended location where your oracle data files will
be saved. This will allow them to remain persistent even across re-creations of
the container.

* Next time you want to start the server, run:

```
docker start nucore_db
# wait, it sometimes takes a few minutes to come up
# "ORA-01033: ORACLE initialization or shutdown in progress" means wait.
```

## Setting up the Oracle Client Drivers

##### Install Oracle 11.2 Instant Client

* Download Basic, SqlPlus, and SDK from: `http://www.oracle.com/technetwork/topics/intel-macsoft-096467.html`

* Install with:

```
sudo mkdir -p /opt/oracle/
cd /opt/oracle

sudo mv ~/Downloads/instantclient-* /opt/oracle
sudo unzip instantclient-basic-macos.x64-12.1.0.2.0.zip
sudo unzip instantclient-sdk-macos.x64-12.1.0.2.0.zip
sudo unzip instantclient-sqlplus-macos.x64-12.1.0.2.0.zip

sudo ln -s instantclient_12_1 instantclient

cd instantclient
sudo ln -s libclntsh.dylib.12.1 libclntsh.dylib
sudo ln -s libocci.dylib.12.1   libocci.dylib

sudo ln -s /opt/oracle/instantclient/sqlplus /usr/local/bin/sqlplus
```

##### Add Environment Variables to profile

* Add to `~/.profile` (bash) or `~/.zprofile` (zsh)

```
export NLS_LANG="AMERICAN_AMERICA.AL32UTF8"
export ORACLE_HOME=/opt/oracle/instantclient
export OCI_DIR=$ORACLE_HOME
```

* `source ~/.profile` or `source ~/.zprofile`, respectively


##### Test your installation:

* Run this command:

```
sqlplus myuser/mypassword@//myserver:1521/mydatabase.mydomain.com
```

* Verify you see an output like this:

```
SQL*Plus: Release 12.1.0.2.0 Production on Fri Mar 3 13:48:51 2017

Copyright (c) 1982, 2016, Oracle.  All rights reserved.

ERROR:
ORA-12154: TNS:could not resolve the connect identifier specified


Enter user-name:
```

* `^D` out of that and carry on.

## Setting up the Database

##### Install Required Gems

* Make sure you have the `activerecord-oracle_enhanced-adapter` and `ruby-oci8` gems
enabled.

##### Set up database configuration

* Copy from oracle settings template

```
cp config/database.yml.oracle.template config/database.yml
```

* Validate keys in settings are correct for your current application

* Start, setup, and seed the oracle container:

```
docker/oracle/setup.sh
# demo:seed is optional
rake demo:seed
```

# Optional Extras

##### Install Oracle SQL Developer

* Download from: `http://www.oracle.com/technetwork/developer-tools/sql-developer/overview/index.html`

* Install into `/Applications`

#### Restore from a backup

Run `bundle exec rake db:oracle_drop_severe`. This will ensure that your database
is clean. Without it the import might skip tables due to them already existing.

Assuming you used `$HOME/oracle_data` as the volume location when you did `docker run`:

Copy the `.dmp` file to `$HOME/oracle_data/admin/xe/dpdump/`

Get a bash shell inside your container:

```
docker exec -it nucore_db bash
```

Run this (replacing the DUMPFILE filename and the second part of REMAP_SCHEMA with your database's username):
```
impdp system/oracle@//localhost:1521/xe DIRECTORY=data_pump_dir DUMPFILE=expdp_schema_COR1PRD_201708191913.dmp REMAP_SCHEMA=bc_nucore:nucore_nu_development
```
