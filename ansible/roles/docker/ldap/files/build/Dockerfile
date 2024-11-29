FROM debian:bookworm-20241111

RUN apt update && apt install -y vim procps rsyslog ldap-utils slapd=2.5.13+dfsg-5

ENV LDAP_ORGANIZATION="devops-core"
ENV LDAP_DOMAIN="devops-core.local"
ENV LDAP_BASE_DN="dc=devops-core,dc=local"
ENV LDAP_ADMIN_USERNAME="admin"
ENV LDAP_ADMIN_PASSWORD="password"
ENV LDAP_BIND_USERNAME="bind"
ENV LDAP_BIND_PASSWORD="password"
ENV LDAP_USERNAME="devops"
ENV LDAP_PASSWORD="password"

ENV LDAP_BACKEND="mdb"
ENV LDAP_CONF_PATH="/etc/ldap/slapd.d"
ENV LDAP_DATA_PATH="/openldap/data"
ENV LDAP_LOG_FILE="/var/log/slapd.log"
ENV LDAP_LOG_LEVEL=-1

ENV LDAP_LDAP_ENABLED=true
ENV LDAP_LDAPS_ENABLED=false
ENV LDAP_LDAPI_ENABLED=true

ENV LDAP_LDAPI_ENABLED=true
ENV LDAP_TLS_CERT_FILE="/openldap/certs/ldap.crt"
ENV LDAP_TLS_KEY_FILE="/openldap/certs/ldap.key"
ENV LDAP_TLS_CA_FILE="/openldap/certs/ca.crt"

ENV LDAP_AUTO_START=true
ENV LDAP_KEEP_ALIVE=true

EXPOSE 389
EXPOSE 636

RUN mkdir -p /openldap && chmod -R ugo+rw /openldap

ADD start /openldap/start
WORKDIR /openldap/start

RUN rm -f init

ENTRYPOINT [ "./start.sh" ]
