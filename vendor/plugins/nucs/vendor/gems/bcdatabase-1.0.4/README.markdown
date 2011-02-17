bcdatabase
==========

*bcdatabase* is a library and utility which provides database configuration parameter management for Ruby on Rails applications.  It provides a simple mechanism for separating database configuration attributes from application source code so that there's no temptation to check passwords into the version control system.  And it centralizes the parameters for a single server so that they can be easily shared among multiple applications and easily updated by a single administrator.

## Installing bcdatabase

    $ gem install bcdatabase

## Using bcdatabase to configure the database for a Rails application

A bog-standard rails application's `config/database.yml` file looks like this:

    development:
      adapter: oracle_enhanced
      database: //localhost/XE
      username: cfg_animal
      password: not-important

    test:
      adapter: oracle_enhanced
      database: //localhost/XE
      username: cfg_animal_test
      password: who-cares

    production:
      adapter: oracle_enhanced
      database: //super/prod
      username: cfg_animal
      password: very-secret

Rails allows this file to contain [ERB][].  `bcdatabase` uses ERB to replace an entire configuration block.  If you wanted to replace, say, just the production block in this example, you would transform it like so:

    <%
      require 'bcdatabase'
      bcdb = Bcdatabase.load
    %>

    development:
      adapter: oracle_enhanced
      database: //localhost/XE
      username: cfg_animal
      password: not-important

    test:
      adapter: oracle_enhanced
      database: //localhost/XE
      username: cfg_animal_test
      password: who-cares

    <%= bcdb.production :prod, :cfg_animal %>

This means "create a YAML block for the *production* environment from the configuration entry named *cfg_animal* in /etc/nubic/db/*prod*.yml."  The method called can be anything:

    <%= bcdb.development :local, :cfg_animal %>
    <%= bcdb.staging 'stage', 'cfg_animal' %>
    <%= bcdb.automated :dev, :cfg_animal_hudson %>

[ERB]: http://www.ruby-doc.org/stdlib/libdoc/erb/rdoc/

## Directly accessing configuration parameters from bcdatabase

More rarely, you might need to access the actual configuration hash, instead of the YAMLized version.  You can access it by invoking `Bcdatabase.load` as shown earlier, then using the bracket operator to specify the configuration you want:

    bcdb[:local, :cfg_animal]

The resulting hash is suitable for passing to `ActiveRecord::Base.establish_connection`, for instance.

## Central configuration files

The database configuration properties for all the applications on a server are stored in one or more files under `/etc/nubic/db` (by default; see "File locations" below).  Each one is a standard YAML file, similar to rails' `database.yml` but with a few enhancements:

* Each file can have a defaults entry which provides attributes which are shared across all configurations in the file
* Each entry defaults its "username" attribute to the name of the entry (useful for Oracle)
* Each entry defaults its "database" attribute to the name of the entry (useful for PostgreSQL)

Since each file can define a set of default properties which are shared by all the contained configurations, it makes sense to group databases which have some shared configuration elements.

### Example

If you have an `/etc/nubic/db/stage.yml` file that looks like this:

    defaults:
      adapter: oracle_enhanced
      database: //mondo/stage
    cfg_animal:
      password: secret
    personnel:
      username: pers
      password: more-secret

You have defined two configuration entries.  `:stage, :cfg_animal`:

    adapter:  oracle_enhanced
    username: cfg_animal
    password: secret
    database: //mondo/stage

and `:bcstage, :personnel`:

    adapter:  oracle_enhanced
    username: pers
    password: more-secret
    database: //mondo/stage

## Obscuring passwords

bcdatabase supports storing encrypted passwords instead of the plaintext ones shown in the previous example.  Encrypted passwords are defined with the key `epassword` instead of `password`.  The library will decrypt the `epassword` value and expose it to the calling code (usually rails) unencrypted under the `password` key.  The `bcdatabase` command line utility handles encrypting passwords; see the next section.

While the passwords are technically encrypted, the master key must be stored on the same machine so that they can be decrypted on demand.  That means this feature only obscures passwords &mdash; it will not deter a determined attacker.

## `bcdatabase` command line utility

The gem includes a command line utility (also called `bcdatabase`) which assists with creating `epassword` entries.  It has online help; after installing the gem, try `bcdatabase help` to read it:

    $ bcdatabase help
    usage: bcdatabase <command> [args]
    Command-line utility for bcdatabase 1.0.0
      encrypt  Encrypts all the password entries in a bcdatabase YAML file
        epass  Generate epasswords from individual database passwords
      gen-key  Generate a key for bcdatabase to use
         help  List commands or display help for one

## File locations

`/etc/nubic/db` is the default place the library will look for the central configuration files.  It may be overridden with the environment variable `BCDATABASE_PATH`.  For instance, if you wanted to keep these files in your home directory on your development machine &mdash; perhaps so that editing them doesn't require elevated privileges &mdash; you could add this to `~/.bashrc`:

    export BCDATABASE_PATH=${HOME}/nubic/db

Similarly, the file containing the encryption password has a sensible default location, but that location can be overridden by setting `BCDATABASE_PASS`.

## Credits

`bcdatabase` was developed at and for the [Northwestern University Biomedical Informatics Center][NUBIC].

[NUBIC]: http://www.nucats.northwestern.edu/centers/nubic/index.html

### Copyright

Copyright (c) 2009 Rhett Sutphin. See LICENSE for details.
