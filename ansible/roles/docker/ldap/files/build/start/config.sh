#!/bin/bash
set -e

echo "running config script..."

cat <<EOF | debconf-set-selections
slapd slapd/internal/generated_adminpw password ${LDAP_ADMIN_PASSWORD}
slapd slapd/internal/adminpw password ${LDAP_ADMIN_PASSWORD}
slapd slapd/password2 password ${LDAP_ADMIN_PASSWORD}
slapd slapd/password1 password ${LDAP_ADMIN_PASSWORD}
slapd slapd/dump_database_destdir string /var/backups/slapd-VERSION
slapd slapd/domain string ${LDAP_DOMAIN}
slapd shared/organization string ${LDAP_ORGANIZATION}
slapd slapd/backend string ${LDAP_BACKEND^^}
slapd slapd/purge_database boolean true
slapd slapd/move_old_database boolean true
slapd slapd/allow_ldap_v2 boolean false
slapd slapd/no_configuration boolean false
slapd slapd/dump_database select when needed
EOF

dpkg-reconfigure -f noninteractive slapd

mkdir -p "${LDAP_DATA_PATH}" 
cp /var/lib/ldap/** "${LDAP_DATA_PATH}"    
chmod -R ugo+rw "${LDAP_DATA_PATH}"

slapmodify -b "cn=config" -F "${LDAP_CONF_PATH}" <<EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcDbDirectory
olcDbDirectory: ${LDAP_DATA_PATH}
EOF

echo "Starting Open LDAP..."
slapd -h "ldapi:/// ldap:///" -F "${LDAP_CONF_PATH}"
while [ ! -e $(ldapsearch ldap:// -x) ]; do sleep 0.1; done

touch /var/log/slapd.log && chmod ugo+rw /var/log/slapd.log

ldapmodify -Y EXTERNAL -H ldapi:/// -Q -v <<EOF
dn: cn=module{0},cn=config
add: olcmoduleload
olcModuleLoad: memberof
-
add: olcmoduleload
olcModuleLoad: refint

dn: cn=config
changetype: modify
replace: olcLogLevel
olcLogLevel: -1
-
replace: olcLogFile
olcLogFile: ${LDAP_LOG_FILE}
EOF

ldapadd -Y EXTERNAL -H ldapi:/// -Q -v <<EOF
dn: olcOverlay=memberof,olcDatabase={1}${LDAP_BACKEND},cn=config
objectClass: olcOverlayConfig
objectClass: olcMemberOf
olcOverlay: memberof
olcMemberOfDangling: ignore
olcMemberOfRefint: TRUE

dn: olcOverlay={1}refint,olcDatabase={1}${LDAP_BACKEND},cn=config
objectClass: olcConfig
objectClass: olcOverlayConfig
objectClass: olcRefintConfig
objectClass: top
olcOverlay: refint
olcRefintAttribute: memberof   
olcRefintAttribute: member
olcRefintAttribute: manager
olcRefintAttribute: owner
EOF

ldapmodify -Y EXTERNAL -H ldapi:/// -Q -v <<EOF
dn: olcDatabase={1}${LDAP_BACKEND},cn=config
changetype:  modify
replace: olcDbIndex
olcDbIndex: uid eq
olcDbIndex: memberOf eq
olcDbIndex: objectClass eq
EOF

ldapadd -H ldapi:/// -x -D "cn=${LDAP_ADMIN_USERNAME},${LDAP_BASE_DN}" -w "$LDAP_ADMIN_PASSWORD" -v <<EOF
dn: ou=groups,${LDAP_BASE_DN}
objectClass: top
objectClass: organizationalUnit

dn: ou=users,${LDAP_BASE_DN}
objectClass: top
objectClass: organizationalUnit

dn: cn=users,ou=groups,${LDAP_BASE_DN}
objectClass: top
objectClass: posixGroup
gidNumber: 1000

dn: cn=${LDAP_BIND_USERNAME},ou=users,${LDAP_BASE_DN}
objectClass: top
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: ${LDAP_BIND_USERNAME}
userPassword: $(slappasswd -n -s $LDAP_BIND_PASSWORD)

dn: cn=${LDAP_USERNAME},ou=users,${LDAP_BASE_DN}
objectClass: top
objectClass: simpleSecurityObject
objectClass: organizationalRole
objectClass: posixAccount
cn: ${LDAP_USERNAME}
uid: ${LDAP_USERNAME}
uidNumber: 1001
gidNumber: 1001
homeDirectory: /home/${LDAP_USERNAME}
userPassword: $(slappasswd -n -s $LDAP_PASSWORD)

dn: cn=admin,ou=groups,${LDAP_BASE_DN}
objectClass: groupOfNames
cn: admin
member: cn=${LDAP_USERNAME},ou=users,${LDAP_BASE_DN}
EOF

if $LDAP_LDAPS_ENABLED; then
echo "Enabling TLS protocol..."
slapadd -b "cn=config" -f "${LDAP_CONF}" <<EOF
add: olcTLSCACertificateFile
olcTLSCACertificateFile: ${LDAP_TLS_CA_FILE}
-
add: olcTLSCertificateFile
olcTLSCertificateFile: ${LDAP_TLS_CERT_FILE}
-
add: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: ${LDAP_TLS_KEY_FILE}
EOF
sed -i -e "s%TLS_CACERT.*%TLS_CACERT    ${LDAP_TLS_CA_FILE}%" /etc/ldap/ldap.conf
echo "*** TLS is enabled"
else
echo "*** TLS is disabled"
fi

echo "Stopping OpenLDAP..."
pkill slapd

echo config script finished
touch init
