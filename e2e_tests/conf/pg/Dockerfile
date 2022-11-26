ARG BACKREST_VERSION="2.42"
ARG CONTAINER_TYPE="ssh"
ARG PG_VERSION="13"

FROM pgbackrest:${BACKREST_VERSION} AS pg_base
ARG PG_VERSION
ARG CONTAINER_TYPE
ENV BACKREST_USER="postgres" \
    BACKREST_GROUP="postgres" \
    PG_VERSION="${PG_VERSION}"
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
    && apt-get autoremove -y \
    && apt-get autopurge -y \
    && rm -rf /var/lib/apt/lists/*
COPY --chmod=640 --chown=${BACKREST_USER}:${BACKREST_GROUP} ./conf/pg/postgresql.auto.conf /var/lib/postgresql/${PG_VERSION}/main/postgresql.auto.conf
COPY --chmod=755 --chown=${BACKREST_USER}:${BACKREST_GROUP} ./conf/pg/pg_prepare-${CONTAINER_TYPE}.sh /var/lib/postgresql/pg_prepare.sh
COPY --chmod=640 --chown=${BACKREST_USER}:${BACKREST_GROUP} ./conf/pg/pg_pgbackrest-${CONTAINER_TYPE}.conf /etc/pgbackrest/pgbackrest.conf

FROM pg_base AS pg-ssh
COPY --chmod=600 --chown=${BACKREST_USER}:${BACKREST_GROUP} ./conf/pg/ssh/authorized_keys /var/lib/postgresql/.ssh/authorized_keys
COPY --chmod=700 --chown=${BACKREST_USER}:${BACKREST_GROUP} ./conf/pg/sshd /var/lib/postgresql/sshd

FROM pg_base AS pg-tls
COPY --chmod=600 --chown=${BACKREST_USER}:${BACKREST_GROUP} ./conf/pgbackrest/cert /etc/pgbackrest/cert

FROM pg-${CONTAINER_TYPE}
ENTRYPOINT ["/entrypoint.sh"]
