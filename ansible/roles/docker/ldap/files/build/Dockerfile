FROM debian:bookworm-20241111

RUN apt update && apt install -y vim procps rsyslog ldap-utils slapd=2.5.13+dfsg-5

ENV LDAP_ORGANIZATION="devops-tools"
ENV LDAP_DOMAIN="devops-tools.local"
ENV LDAP_BASE_DN="dc=devops-tools,dc=local"
ENV LDAP_ADMIN_USERNAME="admin"
ENV LDAP_ADMIN_PASSWORD="password"
ENV LDAP_BIND_USERNAME="bind"
ENV LDAP_BIND_PASSWORD="password"
ENV LDAP_DEFAULT_USERNAME="devops"
ENV LDAP_DEFAULT_PASSWORD="password"

ENV LDAP_BACKEND="mdb"
ENV LDAP_CONF_PATH="/etc/ldap/slapd.d"
ENV LDAP_DATA_PATH="/openldap/data"
ENV LDAP_LOG_LEVEL=-1

ENV LDAP_LDAP_ENABLED=true
ENV LDAP_LDAPI_ENABLED=true
ENV LDAP_AUTO_START=true

EXPOSE 389
EXPOSE 636

RUN mkdir -p /openldap && chmod -R ugo+rw /openldap

ADD start /openldap/start
WORKDIR /openldap/start

RUN rm -f init

ENTRYPOINT [ "/bin/bash", "-c" ]
CMD [ "./entrypoint.sh" ]
