ARG BACKREST_VERSION="2.37"
ARG PG_VERSION="13"

FROM pgbackrest:${BACKREST_VERSION}
ARG PG_VERSION
ENV BACKREST_USER="postgres" \
    BACKREST_GROUP="postgres"
RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        curl \
        gnupg \
    && curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && echo "deb http://apt.postgresql.org/pub/repos/apt/ focal-pgdg main" \
        > /etc/apt/sources.list.d/pgdg.list
RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        apt-utils \
        postgresql-${PG_VERSION} \
        postgresql-contrib-${PG_VERSION} \
        openssh-server \
        rsyslog \
    && /etc/init.d/ssh start \
    && /etc/init.d/rsyslog start \
    && apt-get autoremove -y \
    && apt-get autopurge -y \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 2222

ENTRYPOINT ["/entrypoint.sh"]
