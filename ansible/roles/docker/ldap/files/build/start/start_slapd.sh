#!/bin/bash

if [ ! -f "init" ]; then
  ./config_slapd.sh > config.txt 2> error.txt
  if [ $? -ne 0 ]; then
      cat config.txt >&2
      echo "*************************" >&2
      cat error.txt >&2
      echo "*** failed to run ldap config" >&2
      echo "************************* ERROR" >&2
      tail -f /dev/null
  fi
fi

TEMP_HOSTS="${LDAP_HOSTS}"
$LDAP_ENABLED && TEMP_HOSTS="${TEMP_HOSTS} ldap://"
$LDAP_TLS_ENABLED && TEMP_HOSTS="${TEMP_HOSTS} ldaps://"

# echo "************************* OK"
# slaptest -f "${LDAP_CONF}"
# echo "************************* BASE DN"
# slapdn -f "${LDAP_CONF}" -v "${LDAP_BASE_DN}"
# echo "************************* CAT"
# slapcat -f "${LDAP_CONF}"
# echo "************************* BIND"
# slapdn -f "${LDAP_CONF}" -v "cn=${LDAP_BIND_USERNAME},ou=users,${LDAP_BASE_DN}"
# echo "************************* USER"
# slapdn -f "${LDAP_CONF}" -v "cn=${LDAP_USERNAME},ou=users,${LDAP_BASE_DN}"

# cat config.txt
echo "*** ${TEMP_HOSTS}"
# tail -f /dev/null

/usr/sbin/slapd -4 -d $LDAP_LOG_LEVEL -h "${TEMP_HOSTS}" 
# -F "${LDAP_CONF_PATH}"
