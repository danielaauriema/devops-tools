FROM debian:12.8

RUN apt update && apt install -y vim procps ldap-utils
RUN apt install -y --download-only slapd

# RUN mkdir /etc/ldap/init/ && cp -R /etc/ldap/slapd.d/** /etc/ldap/init/ 

ENV LDAP_ORGANIZATION="devops-core"
ENV LDAP_DOMAIN="devops-core.local"
# ENV LDAP_BASE_DN="dc=nodomain"
ENV LDAP_BASE_DN="dc=devops-core,dc=local"
ENV LDAP_ADMIN_USERNAME="admin"
ENV LDAP_ADMIN_PASSWORD="password"
ENV LDAP_BIND_USERNAME="bind"
ENV LDAP_BIND_PASSWORD="password"
ENV LDAP_USERNAME="devops"
ENV LDAP_PASSWORD="password"

ENV LDAP_BACKEND="mdb"
ENV LDAP_CONF_FILE="./slapd.conf"
# ENV LDAP_CONF_PATH="/openldap/slapd.d"
ENV LDAP_CONF_PATH="/etc/ldap/slapd.d"
ENV LDAP_DATA_PATH="/openldap/data"
ENV LDAP_LOG_LEVEL=-1

ENV LDAP_HOSTS="ldapi://"
ENV LDAP_ENABLED=true
ENV LDAP_TLS_ENABLED=false
ENV LDAP_TLS_CERT_FILE="/openldap/certs/ldap.crt"
ENV LDAP_TLS_KEY_FILE="/openldap/certs/ldap.key"
ENV LDAP_TLS_CA_FILE="/openldap/certs/ca.crt"

EXPOSE 389
EXPOSE 636

RUN mkdir -p /openldap && chmod -R ugo+rw /openldap
# RUN mkdir -p /openldap && chown -R openldap /openldap

ADD start /openldap/start
WORKDIR /openldap/start

# RUN chown -R openldap /openldap

ENTRYPOINT [ "/bin/bash", "-c" ]
CMD [ "./start_ldap.sh" ]

