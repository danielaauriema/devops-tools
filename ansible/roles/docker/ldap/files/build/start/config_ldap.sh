#!/bin/bash
set -e

#   chown -R openldap:openldap /var/run/slapd
#   chown -R openldap:openldap /var/lib/ldap

echo running config script...
# cp -R -u -p /etc/ldap/init/** /etc/ldap/slapd.d/ 

# rm -r /etc/ldap/slapd.d/**
# ls -l /etc/ldap/slapd.d/

# # chmod -R ugo+rwx /etc/ldap/
mkdir -p "${LDAP_DATA_PATH}"
# mkdir -p "${LDAP_CONF_PATH}"

# # cp -R -u -p /etc/ldap/init/** ${LDAP_CONF_PATH} 

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

apt install -y slapd

# echo "*******"
# echo "*******"
# slapcat -n 0
# echo "*******"
# echo "*******"
# slapcat -n 1
# echo "*******"
# echo "*******"


/etc/init.d/slapd start

ldapwhoami -H ldapi:/// -x -D "cn=${LDAP_ADMIN_USERNAME},${LDAP_BASE_DN}" -w "$LDAP_ADMIN_PASSWORD" 

# chmod -R ugo+rw "${LDAP_DATA_PATH}"
# chmod -R ugo+rw "${LDAP_CONF_PATH}"
# # chown -R openldap "${LDAP_DATA_PATH}"
# # chown -R openldap "${LDAP_CONF_PATH}"

# # /usr/share/doc/slapd/examples/slapd.conf

# echo "*** 2.1"
ldapadd -Y EXTERNAL -H ldapi:/// -v <<EOF
dn: cn=module,cn=config
cn: module 
objectClass: olcModuleList
olcModulePath: /usr/lib/ldap
olcModuleLoad: memberof
EOF

ldapadd -Y EXTERNAL -H ldapi:/// -v <<EOF
dn: olcOverlay=memberof,olcDatabase={1}mdb,cn=config
objectClass: olcOverlayConfig
objectClass: olcMemberOf
olcOverlay: memberof
olcMemberOfRefint: TRUE
EOF









# echo "*** 2.2"
# ldapmodify -Y EXTERNAL -H ldapi:/// -v <<EOF
# # Backend memberOf overlay
# dn: olcOverlay={0}memberof,olcDatabase={1}mdb,cn=config
# changetype: add
# objectClass: olcOverlayConfig
# objectClass: olcMemberOf
# olcOverlay: {0}memberof
# olcMemberOfDangling: ignore
# olcMemberOfRefInt: TRUE
# olcMemberOfGroupOC: groupOfUniqueNames
# olcMemberOfMemberAD: uniqueMember
# olcMemberOfMemberOfAD: memberOf
# EOF

# echo "*** 2.3"
# ldapmodify -Y EXTERNAL -H ldapi:/// -v <<EOF
# # Load refint module
# dn: cn=module{0},cn=config
# changetype: modify
# add: olcModuleLoad
# olcModuleLoad: refint.la
# EOF

# echo "*** 2.4"
# ldapmodify -Y EXTERNAL -H ldapi:/// -v <<EOF
# # Backend refint overlay
# dn: olcOverlay={1}refint,olcDatabase={1}mdb,cn=config
# changetype: add
# objectClass: olcOverlayConfig
# objectClass: olcRefintConfig
# olcOverlay: {1}refint
# olcRefintAttribute: owner
# olcRefintAttribute: manager
# olcRefintAttribute: uniqueMember
# olcRefintAttribute: member
# olcRefintAttribute: memberOf
# EOF

# echo "*** 2.5"
# slapmodify -v -b "cn=config" <<EOF
# # Add indexes
# dn: olcDatabase={1}mdb,cn=config
# changetype:  modify
# replace: olcDbIndex
# olcDbIndex: uid eq
# olcDbIndex: mail eq
# olcDbIndex: memberOf eq
# olcDbIndex: entryCSN eq
# olcDbIndex: entryUUID eq
# olcDbIndex: objectClass eq
# EOF

echo "*** 3"
ldapadd -H ldapi:/// -x -D "cn=${LDAP_ADMIN_USERNAME},${LDAP_BASE_DN}" -w "$LDAP_ADMIN_PASSWORD" -v <<EOF
# # dn: ${LDAP_BASE_DN}
# # objectClass: top
# # objectClass: dcObject
# # objectClass: organization
# # o: ${LDAP_ORGANIZATION}

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
member: cn=${LDAP_BIND_USERNAME},ou=users,${LDAP_BASE_DN}
EOF

# slapcat -n 0 | grep olcModuleLoad
# exit 1





# ######################################################################################
echo "*****"
slapcat -n 0 | grep olcModuleLoad

echo "*****"
ldapsearch -Y EXTERNAL -H ldapi:/// -b "dc=devops-core,dc=local" "(uid=devops)" memberof || true
echo "*****"
# ldapsearch -H ldapi:// -x -D "cn=admin,dc=devops-core,dc=local" -w password -b "dc=devops-core,dc=local" "(uid=devops)"
# ldapsearch -H ldapi:// -x -D "cn=admin,dc=devops-core,dc=local" -w password -b "dc=devops-core,dc=local" "(memberof=cn=admin,ou=groups,dc=devops-core,dc=local)"
# echo "*****"

# pkill slapd

# if $LDAP_TLS_ENABLED; then
# echo "Enabling TLS protocol..."
# slapadd -b "cn=config" -f "${LDAP_CONF}" <<EOF
# add: olcTLSCACertificateFile
# olcTLSCACertificateFile: ${LDAP_TLS_CA_FILE}
# -
# add: olcTLSCertificateFile
# olcTLSCertificateFile: ${LDAP_TLS_CERT_FILE}
# -
# add: olcTLSCertificateKeyFile
# olcTLSCertificateKeyFile: ${LDAP_TLS_KEY_FILE}
# EOF
# sed -i -e "s%TLS_CACERT.*%TLS_CACERT    ${LDAP_TLS_CA_FILE}%" /etc/ldap/ldap.conf
# echo "*** TLS is enabled"
# else
# echo "*** TLS is disabled"
# fi







# echo "*** 4"
# slapadd -q -b "cn=config" -f "./slapd.conf" <<EOF
# dn: olcOverlay={0}memberof,olcDatabase={1}mdb,cn=config
# objectClass: olcConfig
# objectClass: olcMemberOf
# objectClass: olcOverlayConfig
# objectClass: top
# olcOverlay: memberof
# olcMemberOfDangling: ignore
# olcMemberOfRefInt: TRUE
# olcMemberOfGroupOC: groupOfNames
# olcMemberOfMemberAD: member
# olcMemberOfMemberOfAD: memberOf
# EOF

# echo "*** 3"
# slapadd -d 66 -q -b "${LDAP_BASE_DN}" -f "./slapd.conf" <<EOF
# dn: olcOverlay={1}refint,olcDatabase={1}mdb,cn=config
# objectClass: olcConfig
# objectClass: olcOverlayConfig
# objectClass: olcRefintConfig
# objectClass: top
# olcOverlay: {1}refint
# olcRefintAttribute: memberof member manager owner
# EOF


# slapmodify -b "cn=config" <<EOF
# dn: olcDatabase={1}mdb,cn=config
# changetype: modify
# replace: olcSuffix
# olcSuffix: ${LDAP_BASE_DN}
# -
# replace: olcRootDN
# olcRootDN: cn=${LDAP_ADMIN_USERNAME},${LDAP_BASE_DN}
# -
# replace: olcRootPW
# olcRootPW: $(slappasswd -s $LDAP_ADMIN_PASSWORD)
# -
# replace: olcDbDirectory
# olcDbDirectory: ${LDAP_DATA_PATH}
# EOF

# echo "*** 1"
# slapadd -d 66 -q -b "cn=config" <<EOF
# dn: cn=module{0},cn=config
# cn: module
# objectClass: olcModuleList
# olcModuleLoad: memberof
# olcModulePath: /usr/lib/ldap
# EOF


# echo "*** 2"
# slapmodify -d 66 -q -b "cn=config" <<EOF
# dn: cn=module{1},cn=config
# add: olcmoduleload
# olcmoduleload: refint
# EOF

echo config script finished

# touch init
