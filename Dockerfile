FROM ubuntu:20.04 AS builder

ARG BACKREST_VERSION
ARG BACKREST_COMPLETION_VERSION

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        make \
        gcc \
        libpq-dev \
        libssl-dev \
        libxml2-dev \
        pkg-config \
        liblz4-dev \
        libzstd-dev \
        libbz2-dev \
        libz-dev \
        libyaml-dev \
        wget \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://github.com/pgbackrest/pgbackrest/archive/release/${BACKREST_VERSION}.tar.gz -O /tmp/pgbackrest-${BACKREST_VERSION}.tar.gz \
    && tar -xzf /tmp/pgbackrest-${BACKREST_VERSION}.tar.gz -C /tmp \
    && mv /tmp/pgbackrest-release-${BACKREST_VERSION} /tmp/pgbackrest-release \
    && cd /tmp/pgbackrest-release/src \
    && ./configure \
    && make

RUN wget https://github.com/woblerr/pgbackrest-bash-completion/archive/${BACKREST_COMPLETION_VERSION}.tar.gz -O /tmp/pgbackrest-bash-completion-${BACKREST_COMPLETION_VERSION}.tar.gz \
    && tar -xzf /tmp/pgbackrest-bash-completion-${BACKREST_COMPLETION_VERSION}.tar.gz -C /tmp \
    && mv /tmp/pgbackrest-bash-completion-$(echo ${BACKREST_COMPLETION_VERSION} | tr -d v) /tmp/pgbackrest-bash-completion

FROM ubuntu:20.04

ARG REPO_BUILD_TAG

ENV TZ="Etc/UTC" \
    BACKREST_USER="pgbackrest" \
    BACKREST_UID=2001 \
    BACKREST_GROUP="pgbackrest" \
    BACKREST_GID=2001 \
    BACKREST_HOST_TYPE="ssh" \
    BACKREST_TLS_WAIT=15 \
    BACKREST_TLS_SERVER="disable"

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        postgresql-client \
        ca-certificates \
        tzdata \
        libxml2 \
        gosu \
        openssh-client \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid ${BACKREST_GID} ${BACKREST_GROUP} \
    && useradd --shell /bin/bash --uid ${BACKREST_UID} --gid ${BACKREST_GID} -m ${BACKREST_USER} \
    && mkdir -p -m 750 \
        /home/${BACKREST_USER}/.bash_completion.d \
        /var/log/pgbackrest \
        /var/lib/pgbackrest \
        /var/spool/pgbackrest \
        /etc/pgbackrest \
        /etc/pgbackrest/conf.d \
        /etc/pgbackrest/cert \
    && touch /etc/pgbackrest/pgbackrest.conf \
    && chmod 640 /etc/pgbackrest/pgbackrest.conf \
    && chown -R ${BACKREST_USER}:${BACKREST_GROUP} \
        /home/${BACKREST_USER}/.bash_completion.d \
        /var/log/pgbackrest \
        /var/lib/pgbackrest \
        /var/spool/pgbackrest \
        /etc/pgbackrest \
    && unlink /etc/localtime \
    && cp /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo "${TZ}" > /etc/timezone

COPY --chmod=755 files/entrypoint.sh /entrypoint.sh
COPY --from=builder --chown=${BACKREST_USER}:${BACKREST_GROUP} /tmp/pgbackrest-bash-completion/pgbackrest-completion.sh /home/${BACKREST_USER}/.bash_completion.d/pgbackrest-completion.sh
COPY --from=builder /tmp/pgbackrest-release/src/pgbackrest /usr/bin/pgbackrest

LABEL \
    org.opencontainers.image.version="${REPO_BUILD_TAG}" \
    org.opencontainers.image.source="https://github.com/woblerr/docker-pgbackrest"

ENTRYPOINT ["/entrypoint.sh"]

CMD ["pgbackrest", "version"]