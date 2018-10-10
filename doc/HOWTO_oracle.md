# Running Oracle in Development

Follow these instructions to set up the Oracle database to run in Docker, but the app itself in your native environment.

## Setting up the Oracle Server with Docker

### Set up Docker and Docker Hub

1. Install Docker for Mac by running `brew cask install docker`
1. Sign up for a Docker Hub account at https://hub.docker.com/. If you already have a Docker Hub account, you can skip this step and use your existing account.
1. Go to https://store.docker.com/images/oracle-database-enterprise-edition and click the button **Proceed to Checkout**. Complete and submit the form in order to get access to the free container that Oracle provides.
1. In your terminal, make sure that you are logged in with your Docker Hub credentials by running `docker login`.

### Start an Oracle container

```
# Feel free to change this to a more suitable directory on your computer.
# Specifying a directory for the container allows you to reuse the development
# data, and skips the initialization of an empty database every time you
# restart the container.
ORACLE_DATA_DIR=$HOME/oracle_data

# Run the Oracle image as a container named oracle, storing data
# in the directory specified above. When you run this for the first time,
# it will take a while to download the image and initialize the database.
#
# When the output in the terminal includes a line like:
#
#   Done ! The database is ready for use .
#
# you can use the database
docker run \
  --interactive \
  --name oracle \
  --publish 1521:1521 \
  --tty \
  --volume $ORACLE_DATA_DIR:/ORCL \
  store/oracle/database-enterprise:12.2.0.1
```

When you no longer need the database, in another terminal tab run:

```
docker stop oracle
```

The next time you need the database, start it just by running:

```
docker start --interactive oracle
```

## Setting up the Oracle Client Drivers

### Install Oracle Instant Client

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

### Set Up Environment Variables

1. Add to `~/.profile` (bash) or `~/.zprofile` (zsh)

```
# The Oracle adapter for ActiveRecord uses this password to connect as a
# system user, to be able to create and drop databases appropriately.
export ORACLE_SYSTEM_PASSWORD=Oradoc_db1

# This is used to specify the default language and encoding for Oracle clients
export NLS_LANG="AMERICAN_AMERICA.UTF8"
```

1. `source ~/.profile` or `source ~/.zprofile`, to load the changes you just made


### Test Your Installation

To connect to the Oracle server, run:

```
sqlplus "sys/Oradoc_db1@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=localhost)(PORT=1521))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=ORCLCDB.localdomain)))" as sysdba
```

Your output should show something like this:

```
Connected to:
Oracle Database 12c Enterprise Edition Release 12.2.0.1.0 - 64bit Production

SQL> 
```

## Setting up the Database

1. Make sure you have the `activerecord-oracle_enhanced-adapter` and `ruby-oci8` gems enabled in your `Gemfile`.
1. Copy the Oracle template for `database.yml` by running `cp config/database.yml.oracle.template config/database.yml`.
1. Run `bundle exec rake db:setup`.
1. Optionally, run `bundle exec rake demo:seed` if you want to populate the database with demo data.

# Optional Extras

## Install Oracle SQL Developer

* Download from: `http://www.oracle.com/technetwork/developer-tools/sql-developer/overview/index.html`

* Install into `/Applications`

## Restore From Backup

Run `bundle exec rake db:oracle_drop_severe`. This will ensure that your database
is clean. Without it the import might skip tables due to them already existing.

Assuming you used `$HOME/oracle_data` as the volume location when you did `docker run`:

1. Copy the `.dmp` file to `$ORACLE_DATA_DIR/u01/app/oracle/admin/ORCL/dpdump/` (assuming you set `ORACLE_DATA_DIR` above), so it is located in the server’s default data pump directory.

1. Start a bash shell in the `oracle` container:

    ```
    docker exec \
      --interactive \
      --tty \
      oracle \
      bash
    ```

1. Import the dump, replacing DUMPFILE with the name of your dump file, and REMAP_SCHEMA with your database’s username if necessary:

```
impdp \
  system/Oradoc_db1@//localhost:1521/ORCLCDB \
  DIRECTORY=data_pump_dir \
  DUMPFILE=expdp_schema_COR1PRD_201810021913.dmp \
  REMAP_SCHEMA=nucore_open_development
```
