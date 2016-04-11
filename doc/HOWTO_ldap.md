# HOWTO Configure NUcore for LDAP Authentication

## Enabling LDAP Authentication On NUcore

NUcore uses [Devise](https://github.com/plataformatec/devise) for authentication, and the [ldap_authenticatable](https://github.com/cschiewek/devise_ldap_authenticatable) Devise module for LDAP authentication. When LDAP is enabled on NUcore Devise will try to authenticate users against both the LDAP server and the local users table. Whichever works first wins. If neither works login is denied.
To configure NUcore to use LDAP you need to copy **config/ldap.yml.template** to **config/ldap.yml**. The mere existence of that file enables LDAP authentication. The default settings will work for the test LDAP server described in the previous sections of this document. You’ll need to change host: if you are using an existing LDAP server or if the test LDAP server is not on the same computer as NUcore.

### Configuring The LDAP dn
LDAP authenticates users with a distinguished name (dn). The dn is typically composed of multiple LDIF attributes. One of the attributes of the dn will specify the user’s login. The additional attributes of the dn, for NUcore, are expected to be consistent across all users.

LDAP users allowed to access NUcore must have a password-less record in NUcore’s users table. The record’s username attribute must correspond to the login part of the user’s LDAP dn. The LDIF attribute identifying the login must be the value of ldap.yml’s attribute: key. The additional LDIF attributes that make up the remainder of the LDAP dn must be the value of the base: key.

### Testing NUcore LDAP Authentication

Make sure you have a password-less user in NUcore that corresponds to the LDAP user we created previously:

From NUcore’s Rails.root...

    script/console
    > User.create!(:username => 'cgreen', :first_name
    => 'Chico', :last_name => 'Green', :email => 'cgreen@example.com')

Now fire up NUcore and try logging in with username ‘cgreen’ and password ‘secret’. You should login successfully. Now, check the standard output of the LDAP server and you should see the authentication query made by NUcore.

## Create a test LDAP Server locally on Mac OS X

`brew install openldap`

### Configure the LDAP Server

`sudo cp /etc/openldap/slapd.conf.default to /etc/openldap/slapd.conf`

Some newer versions of openldap may not even allow plain text root passwords, so generate one using: `slappasswd -s secret`

### Sample slapd.conf

    #
    # See slapd.conf(5) for details on configuration options.
    # This file should NOT be world readable.
    #
    include   /usr/local/etc/openldap/schema/core.schema
    include   /usr/local/etc/openldap/schema/cosine.schema
    include   /usr/local/etc/openldap/schema/inetorgperson.schema

    # Define global ACLs to disable default read access.

    # Do not enable referrals until AFTER you have a working directory
    # service AND an understanding of referrals.
    #referral ldap://root.openldap.org

    pidfile   /usr/local/var/run/slapd.pid
    argsfile  /usr/local/var/run/slapd.args

    # Load dynamic backend modules:
    # modulepath  /usr/local/Cellar/openldap/2.4.33/libexec/openldap
    # moduleload  back_bdb.la
    # moduleload  back_hdb.la
    # moduleload  back_ldap.la

    # Sample security restrictions
    # Require integrity protection (prevent hijacking)
    # Require 112-bit (3DES or better) encryption for updates
    # Require 63-bit encryption for simple bind
    # security ssf=1 update_ssf=112 simple_bind=64

    # Sample access control policy:
    # Root DSE: allow anyone to read it
    # Subschema (sub)entry DSE: allow anyone to read it
    # Other DSEs:
    #   Allow self write access
    #   Allow authenticated users read access
    #   Allow anonymous users to authenticate
    # Directives needed to implement policy:
    # access to dn.base="" by * read
    # access to dn.base="cn=Subschema" by * read
    # access to *
    # by self write
    # by users read
    # by anonymous auth
    #
    # if no access controls are present, the default policy
    # allows anyone and everyone to read anything but restricts
    # updates to rootdn.  (e.g., "access to * by * read")
    #
    # rootdn can always read and write EVERYTHING!

    #######################################################################
    # BDB database definitions
    #######################################################################

    database  bdb
    suffix    "dc=example,dc=com"
    rootdn    "cn=admin,dc=example,dc=com"
    # Cleartext passwords, especially for the rootdn, should
    # be avoid.  See slappasswd(8) and slapd.conf(5) for details.
    # Use of strong authentication encouraged.
    #rootpw   secret
    rootpw          {SSHA}bLqKkdr2MxXPLLpU4d7bvSYgM0D6zlh/
    access to attr=userPassword
           by dn="cn=admin,dc=example,dc=com" write
           by self write
           by * auth
    access to *
           by dn="cn=admin,dc=example,dc=com"  write
           by dn="cn=cgreen,dc=example,dc=com" read
           by users read
           by self write
           by * auth


    # The database directory MUST exist prior to running slapd AND
    # should only be accessible by the slapd and slap tools.
    # Mode 700 recommended.
    directory /usr/local/var/openldap-data
    # Indices to maintain
    index objectClass eq


### Start the server

`sudo /usr/libexec/slapd -d -1`

### Seed the directory

#### Add an organization

For testing you’ll need at least one organization and one user in the LDAP directory. First you need to create the organization:

`ldapadd -x -D "cn=admin,dc=example,dc=com" -w secret -f org.ldif`

org.ldif needs to be a LDAP data interchange formatted file. See the appendix for an example.

#### Add a user

`ldapadd -x -D "cn=admin,dc=example,dc=com" -w secret -f usr.ldif`

usr.ldif also needs to be a LDAP data interchange formatted file. See the appendix for an example.

### Search the LDAP Directory
`ldapsearch -x -D "cn=admin,dc=example,dc=com" -w secret -b "dc=example,dc=com" “cn=*”`

You should get a result that looks similar to:

    # extended LDIF
    #
    # LDAPv3
    # base <dc=example,dc=com> with scope subtree
    # filter: cn=*
    # requesting: ALL
    #

    # cgreen, example.com
    dn: cn=cgreen,dc=example,dc=com
    cn: Chico Green
    cn: cgreen
    givenName: Chico
    sn: Green
    mail: cgreen@example.com
    userPassword:: bm90Z3VtcA==
    objectClass: person
    objectClass: organizationalPerson
    objectClass: inetOrgPerson
    # search result
    search: 2
    result: 0 Success
    # numResponses: 2
    # numEntries: 1



####org.ldif

        dn: dc=example,dc=com
        objectClass: top
        objectClass: dcObject
        objectClass: organization
        dc: example
        o: Table XI

#### usr.ldif

        dn: cn=cgreen,dc=example,dc=com
        cn: Chico Green
        gn: Chico
        sn: Green
        mail: cgreen@example.com
        userPassword: secret
        objectClass: person
        objectClass: organizationalPerson
        objectClass: inetOrgPerson
