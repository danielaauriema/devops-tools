#!/bin/bash
if [ "$1" == "build" ]; then
    docker system prune -f 
    docker build -t devops/ldap_test .
    rm -f start/init
fi
if [ "$1" == "config" ]; then
    rm -f start/init
fi
docker run -it -p "389:389" --rm -v $(pwd)/start:/openldap/start  devops/ldap_test ./config.sh
