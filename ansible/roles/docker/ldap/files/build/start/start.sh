#!/bin/bash

echo "*** Starting OpenLDAP..."

if [ ! -f "init" ]; then
  if ! ./config.sh; then
      echo "*** LDAP CONFIGURATION ERROR"
      exit 1
  fi
fi

declare -a LDAP_HOSTS=()
if $LDAP_LDAP_ENABLED; then LDAP_HOSTS+=("ldap://"); fi
if $LDAP_LDAPS_ENABLED; then LDAP_HOSTS+=("ldaps://"); fi
if $LDAP_LDAPI_ENABLED; then LDAP_HOSTS+=("ldapi://"); fi

HOSTS="${LDAP_HOSTS[*]}"
/usr/sbin/slapd -4 -d "${LDAP_LOG_LEVEL}" -h "${HOSTS}" -F "${LDAP_CONF_PATH}"
