# HOWTO Configure NUcore for LDAP Authentication

## Enabling LDAP Authentication On NUcore

NUcore uses [Devise](https://github.com/plataformatec/devise) for authentication,
and the [`ldap_authenticatable`](https://github.com/cschiewek/devise_ldap_authenticatable)
Devise module for LDAP authentication.

When LDAP is enabled on NUcore Devise will try to authenticate users against
both the LDAP server and the local users table. Whichever works first wins.
If neither works login is denied.

NUcore will activate LDAP authentication if a configuration file exists.
The example config file provided with NUcore is enough to get started:

```bash
cp config/ldap.yml.template config/ldap.yml
```

The default settings are for an LDAP server running on `localhost` port 389,
which should work for the test LDAP server described below.
Change the `host:` value if you are using an external LDAP server.

### Configuring The LDAP dn

LDAP authenticates users with a distinguished name (`dn`), which is typically
composed of multiple LDIF attributes. One of the attributes of the `dn` will
specify the user’s login. The additional attributes, for NUcore, are expected
to be consistent across all users.

LDAP users allowed to access NUcore must have a password-less record in
NUcore’s users table. The record’s username attribute must correspond to the
login part of the user’s LDAP `dn`. The LDIF attribute identifying the login
must be the value of `ldap.yml`'s `attribute: key`.
The additional LDIF attributes that make up the remainder of the LDAP `dn` must
be the value of the `base: key`.

### Setting up an LDAP Server on Mac OS

As root, copy this configuration to `/etc/openldap/slapd.conf`:

```
### Sample slapd.conf
#
# See slapd.conf(5) for details on configuration options.
# This file should NOT be world readable.
#
include /private/etc/openldap/schema/core.schema
include /private/etc/openldap/schema/cosine.schema
include /private/etc/openldap/schema/inetorgperson.schema

# Define global ACLs to disable default read access.

# Do not enable referrals until AFTER you have a working directory
# service AND an understanding of referrals.
#referral ldap://root.openldap.org

pidfile /private/var/db/openldap/run/slapd.pid
argsfile /private/var/db/openldap/run/slapd.args

# Load dynamic backend modules:
# modulepath /usr/libexec/openldap
# moduleload back_bdb.la
# moduleload back_hdb.la
# moduleload back_ldap.la

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

database bdb
suffix "dc=example,dc=com"
rootdn "cn=admin,dc=example,dc=com"
# Cleartext passwords, especially for the rootdn, should
# be avoid.  See slappasswd(8) and slapd.conf(5) for details.
# Use of strong authentication encouraged.
# rootpw secret
rootpw {SSHA}bLqKkdr2MxXPLLpU4d7bvSYgM0D6zlh/

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
directory /private/var/db/openldap/openldap-data
# Indices to maintain
index objectClass eq
```

The configuration above sets `rootpw` (the root password) to "secret".
To use a different password, encrypt it with `slappasswd` and use its output to
replace the `rootpw` value in the config:

```bash
slappasswd -s "another_password"
```

Make sure `slapd.conf` is `root`-owned and mode `0600` (meaning only `root` may read and write):

```bash
sudo chown root:wheel /etc/openldap/slapd.conf &&
sudo chmod 0600 /etc/openldap/slapd.conf
```

### Running the LDAP Server

```bash
sudo /usr/libexec/slapd -d -1
```

This will start the server, keeping it in the foreground while sending logs to
standard output. If you need to see more verbose logging, including the protocol
back-and-forth, change the `-1` to `-7`.

### Seed the directory

#### Add an organization

For testing you’ll need at least one organization in the LDAP directory.
To create the organization:

```bash
ldapadd -x -D "cn=admin,dc=example,dc=com" -w secret -f org.ldif
```

`org.ldif` is a file in LDAP data interchange format. Here's an example:

```
dn: dc=example,dc=com
objectClass: top
objectClass: dcObject
objectClass: organization
dc: example
o: Table XI
```

#### Add a user

You will also need at least one user in the LDAP directory. To create a user:

```bash
ldapadd -x -D "cn=admin,dc=example,dc=com" -w secret -f usr.ldif
```

`usr.ldif` is a file in LDAP data interchange format. Here's an example:

```
dn: cn=cgreen,dc=example,dc=com
cn: Chico Green
gn: Chico
sn: Green
mail: cgreen@example.com
userPassword: secret
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
```

### Search the LDAP Directory

```bash
ldapsearch -x -D "cn=admin,dc=example,dc=com" -w secret -b "dc=example,dc=com" “cn=*”
```

You should see output similar to this:

```
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
```

### Testing NUcore LDAP Authentication Integration

Create a password-less `User`:

```bash
bundle exec rails console
[1] pry(main)> User.create!(username: "cgreen", first_name: "Chico", last_name: "Green", email: "cgreen@example.com")
```

Try logging in to NUcore with username `cgreen` and password `secret`.
You should login successfully, and you should see activity in the LDAP server's
the standard output.
