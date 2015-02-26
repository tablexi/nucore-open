# NU Core Open

Open source version of Northwestern University Core Facility Management Software

## Quickstart

Welcome to NU Core! This guide will help you get a development environment up and running. It makes a few assumptions:

1. You write code on a Mac.
2. You have a running Oracle or MySQL instance with two brand new databases.
3. You have the following installed:
    * [Ruby 2.1](http://www.ruby-lang.org/en)
    * [Bundler](http://gembundler.com)
    * [Git](http://git-scm.com)

### Spin it up

1. Download the project code from Github

    ```
    git clone git@github.com:tablexi/nucore-open.git nucore
    ```

2. Install dependencies

    ```
    cd nucore
    bundle install --without oracle
    ```

3. Configure your databases

    ```
    cp config/database.yml.mysql.template config/database.yml
    ```

    Edit the adapter, database, username, and password settings for both the development and test DBs to match your database instance

4. Create your databases

    ```
    rake db:create
    rake db:schema:load
    rake db:schema:load RAILS_ENV=test
    ```

5. Seed your development database

    ```
    rake db:seed
    rake demo:seed
    ```

6. Start your server

    ```
    bin/rails s
    ```

7. Log in

    Visit http://localhost:3000

    `demo:seed` creates several users with various permissions. All users have the default password of `password`

    | Email/username     | Role |
    | ------------------ | ---- |
    | admin@example.com  | Admin|
    | ppi123@example.com | PI   |
    | sst123@example.com | Normal User |
    | ast123@example.com | Facility Staff |
    | ddi123@example.com | Facility Director |

8. Play around! You're running NU Core!


### Test it

NU Core uses [Rspec](http://rspec.info) to run tests. Try any of the following from NU Core's root directory.

* To run all tests (this will take awhile!)
    rake spec

* To run just the model tests
    rake spec:models

* To run just the controller tests
    rake spec:controllers


## Learn more

There are valuable resources in the NU Core's doc directory.

* Need to move changes between nucore-open and your fork? [**See HOWTO_forks.txt**](doc/HOWTO_forks.md)

* Need help getting Oracle running on your Mac? [**See HOWTO_oracle.txt**](doc/HOWTO_oracle.txt)

* Want to authenticate users against your institution's LDAP server? [**See HOWTO_ldap.txt**](doc/HOWTO_ldap.md)

* Need to use a 3rd party service with your NU Core? [**See HOWTO_external_services.txt**](doc/HOWTO_external_services.md)

* Need to asynchronously monitor some aspect of NU Core? [**See HOWTO_daemons.txt**](doc/HOWTO_daemons.txt)
