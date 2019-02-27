# Running SQLite in Development

If you really want, you can use nucore with a SQLite database.  The procedere requires a couple of manual changes and thus is (besides performance considerations) **not a good idea for your production environment**.  Note that this guide **might be out of date** and aimed at users of UNIX-like systems. For installation, you still need to follow the `README`, this guide is meant for an audience that are somewhat familiar with setting up Ruby on Rails applications.

## Require the SQLite gem

Add the following line to your `Gemfile`

    gem 'sqlite3', '~> 1.3.6'

. The version restriction might be out of date - it stems from a 'bug' in rails or ActiveRecord (one example related issue is https://github.com/rails/rails/issues/35153 ).

Run

    bundle install

to install the sqlite3 gem once you made the changes to the `Gemfile`.

## Remove MySQLisms from schema file

Run this command to remove the MySQL-specific part of `db/schema.rb` (from which the database initialization is derived):

    sed -i 's|, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8"||g' db/schema.rb

## Configure the database to be used

Instead of using the provided `config/database.yml.mysql.template`, create the file `config/database.yml` with following content:

    default: &default
      adapter: sqlite3
      pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
      timeout: 5000
    
    development:
      <<: *default
      database: db/development.sqlite3
    
    # Warning: The database defined as "test" will be erased and
    # re-generated from your development database when you run "rake".
    # Do not set this db to the same as development or production.
    test:
      <<: *default
      database: db/test.sqlite3

Note that you also **could** define production settings, but since its a bad idea, we leave this exercise to the reader.

### Initialize and populate the database

Run

    rails db:schema:load

to create the necessary tables. If you wish, populate the database with demo data by calling

    rails demo:seed

.
