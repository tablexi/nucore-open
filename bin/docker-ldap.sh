#!/bin/bash -e
docker run --name ldap-service --hostname ldap-service -p 389:389 -p 636:636 --detach osixia/openldap
docker run --name phpldapadmin-service --hostname phpldapadmin-service --link ldap-service:ldap-host --env PHPLDAPADMIN_LDAP_HOSTS=ldap-host --detach -p 8081:443 osixia/phpldapadmin

echo "Go to: https://localhost:8081"
echo "Login DN: cn=admin,dc=example,dc=org"
echo "Password: admin"
