#!/bin/bash

echo "*** Starting OpenLDAP..."
ls -l


if [ ! -f "init" ]; then
  ./config.sh # > config.txt 2> error.txt
  if [ $? -ne 0 ]; then
  #     cat config.txt 

  #     echo "*************************" 
  #     cat error.txt 
  #     echo "*** failed to run ldap config" 
      echo "************************* ERROR"
      if [ $LDAP_KEEP_ALIVE ]; then
        tail -f /dev/null
      fi
  fi
fi

declare -a LDAP_HOSTS=()
if $LDAP_LDAP_ENABLED ; then LDAP_HOSTS+=("ldap://"); fi
if $LDAP_LDAPS_ENABLED ; then LDAP_HOSTS+=("ldaps://"); fi
if $LDAP_LDAPI_ENABLED ; then LDAP_HOSTS+=("ldapi://"); fi


if $LDAP_AUTO_START; then
  HOSTS="${LDAP_HOSTS[@]}"
  /usr/sbin/slapd -4 -d $LDAP_LOG_LEVEL -h "${HOSTS}" -F "${LDAP_CONF_PATH}"
else
  if [ $LDAP_KEEP_ALIVE ]; then
    tail -f /dev/null
  fi
fi
