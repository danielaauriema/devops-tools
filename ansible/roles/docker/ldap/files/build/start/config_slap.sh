#!/bin/bash
set -e

echo running config script...
# cp -R -u -p /etc/ldap/init/** /etc/ldap/slapd.d/ 

# rm -r /etc/ldap/slapd.d/**
# ls -l /etc/ldap/slapd.d/

# # chmod -R ugo+rwx /etc/ldap/
mkdir -p "${LDAP_DATA_PATH}"
# mkdir -p "${LDAP_CONF_PATH}"

# # cp -R -u -p /etc/ldap/init/** ${LDAP_CONF_PATH} 

# chmod -R ugo+rw "${LDAP_DATA_PATH}"
# chmod -R ugo+rw "${LDAP_CONF_PATH}"
# # chown -R openldap "${LDAP_DATA_PATH}"
# # chown -R openldap "${LDAP_CONF_PATH}"

# # /usr/share/doc/slapd/examples/slapd.conf

echo "*** 1"
cat << EOF > "${LDAP_CONF_FILE}"
# Schema and objectClass definitions
include         /etc/ldap/schema/core.schema
include         /etc/ldap/schema/cosine.schema
include         /etc/ldap/schema/nis.schema
# include         /etc/ldap/schema/inetorgperson.schema

pidfile         /var/run/slapd/slapd.pid
argsfile        /var/run/slapd/slapd.args

# Read slapd.conf(5) for possible values
loglevel        ${LDAP_LOG_LEVEL}

# Where the dynamically loaded modules are stored
modulepath      /usr/lib/ldap
moduleload      back_mdb
# moduleload      refint
# moduleload      memberof

# The maximum number of entries that is returned for a search operation
sizelimit 500

# The tool-threads parameter sets the actual amount of cpu's that is used
# for indexing.
tool-threads 1

#######################################################################
# Specific Backend Directives for mdb:
# Backend specific directives apply to this backend until another
# 'backend' directive occurs
backend         mdb

database        mdb
suffix         "${LDAP_BASE_DN}"
directory       ${LDAP_DATA_PATH}
rootdn         "cn=${LDAP_ADMIN_USERNAME},${LDAP_BASE_DN}"
rootpw          $(slappasswd -n -s $LDAP_ADMIN_PASSWORD)
index           objectClass eq

lastmod         on
checkpoint      512 30

# by dn.base="cn=${LDAP_ADMIN_USERNAME},${LDAP_BASE_DN}" write
access to attrs=userPassword
    by self write
    by anonymous auth
    by * read
access to dn.base="" 
    by * read
access to *
    by * read
EOF


# echo "*** 2"
# slapadd -F "${LDAP_CONF_PATH}" -f "${LDAP_CONF_FILE}" -v -b "cn=config" <<EOF
# EOF

ls -l /etc/ldap/slapd.d

echo "*** 2.0"
# slapmodify  -F "${LDAP_CONF_PATH}" -v -b "cn=config" <<EOF
slapmodify -v -b "cn=config" <<EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: ${LDAP_BASE_DN}
-
replace: olcRootDN
olcRootDN: cn=${LDAP_ADMIN_USERNAME},${LDAP_BASE_DN}
-
replace: olcRootPW
olcRootPW: $(slappasswd -s $LDAP_ADMIN_PASSWORD)
# -
# replace: olcDbDirectory
# olcDbDirectory: ${LDAP_DATA_PATH}
EOF

echo "*** 2.1"
slapmodify -v -b "cn=config" <<EOF
# Load memberof module
dn: cn=module{0},cn=config
changetype: modify
add: olcModuleLoad
olcModuleLoad: memberof
EOF

echo "*** 2.2"
slapmodify -v -b "cn=config" <<EOF
# Backend memberOf overlay
dn: olcOverlay={0}memberof,olcDatabase={1}mdb,cn=config
changetype: add
objectClass: olcOverlayConfig
objectClass: olcMemberOf
olcOverlay: {0}memberof
olcMemberOfDangling: ignore
olcMemberOfRefInt: TRUE
olcMemberOfGroupOC: groupOfUniqueNames
olcMemberOfMemberAD: uniqueMember
olcMemberOfMemberOfAD: memberOf
EOF

echo "*** 2.3"
slapmodify -v -b "cn=config" <<EOF
# Load refint module
dn: cn=module{0},cn=config
changetype: modify
add: olcModuleLoad
olcModuleLoad: refint
EOF

echo "*** 2.4"
slapmodify -v -b "cn=config" <<EOF
# Backend refint overlay
dn: olcOverlay={1}refint,olcDatabase={1}mdb,cn=config
changetype: add
objectClass: olcOverlayConfig
objectClass: olcRefintConfig
olcOverlay: {1}refint
olcRefintAttribute: owner
olcRefintAttribute: manager
olcRefintAttribute: uniqueMember
olcRefintAttribute: member
olcRefintAttribute: memberOf
EOF


echo "*** 2.5"
slapmodify -v -b "cn=config" <<EOF
# Add indexes
dn: olcDatabase={1}mdb,cn=config
changetype:  modify
replace: olcDbIndex
olcDbIndex: uid eq
olcDbIndex: mail eq
olcDbIndex: memberOf eq
olcDbIndex: entryCSN eq
olcDbIndex: entryUUID eq
olcDbIndex: objectClass eq
EOF

echo "*** 3"
slapadd -b "${LDAP_BASE_DN}" <<EOF
# dn: ${LDAP_BASE_DN}
# objectClass: top
# objectClass: dcObject
# objectClass: organization
# o: ${LDAP_ORGANIZATION}

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

slapcat -n 0 | grep olcModuleLoad
# exit 1

# echo "*****"
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

touch init
