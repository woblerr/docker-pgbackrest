ARG BACKREST_VERSION="2.58.0"
ARG CONTAINER_TYPE="ssh"
ARG PG_VERSION="16"

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
        lsb-release \
    && curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg \
    && echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" \
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
RUN mkdir -p -m 700 \
        /var/lib/postgresql/.ssh \
        /var/lib/postgresql/sshd \
    && chown -R ${BACKREST_USER}:${BACKREST_GROUP} \
        /var/lib/postgresql/.ssh \
        /var/lib/postgresql/sshd
COPY --chmod=600 --chown=${BACKREST_USER}:${BACKREST_GROUP} ./conf/ssh /var/lib/postgresql/.ssh
COPY --chmod=600 --chown=${BACKREST_USER}:${BACKREST_GROUP} ./conf/pg/sshd /var/lib/postgresql/sshd

FROM pg_base AS pg-tls
RUN mkdir -p -m 700 \
        /var/lib/postgresql/.ssh \
    && chown -R ${BACKREST_USER}:${BACKREST_GROUP} \
        /var/lib/postgresql/.ssh
# Copy onle id_rsa_sftp and d_rsa_sftp.pub.
COPY --chmod=600 --chown=${BACKREST_USER}:${BACKREST_GROUP} ./conf/ssh/id_rsa_sftp* /var/lib/postgresql/.ssh/
COPY --chmod=600 --chown=${BACKREST_USER}:${BACKREST_GROUP} ./conf/pgbackrest/cert /etc/pgbackrest/cert

FROM pg-${CONTAINER_TYPE}
ENTRYPOINT ["/entrypoint.sh"]
