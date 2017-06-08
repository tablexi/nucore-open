#!/bin/bash -e
docker run --name ldap-service --hostname ldap-service -p 389:389 -p 636:636 --detach osixia/openldap
docker run --name phpldapadmin-service --hostname phpldapadmin-service --link ldap-service:ldap-host --env PHPLDAPADMIN_LDAP_HOSTS=ldap-host --detach -p 8081:443 osixia/phpldapadmin

# PHPLDAP_IP=$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" phpldapadmin-service)

echo "Go to: https://localhost:8081"
echo "Login DN: cn=admin,dc=example,dc=org"
echo "Password: admin"

# Import this to PHP
# dn: uid=jhl941,dc=example,dc=org
# uid: jhl941
# cn: jason,hanggi,jason hanggi
# gn: Jason
# sn: Hanggi
# mail: jason+ldap@tablexi.com
# userPassword: secret
# objectClass: top
# objectClass: person
# objectClass: organizationalPerson
# objectClass: inetOrgPerson
