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

ENV TZ="Europe/Moscow" \
    BACKREST_USER="pgbackrest" \
    BACKREST_UID=2001 \
    BACKREST_GROUP="pgbackrest" \
    BACKREST_GID=2001

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y  --no-install-recommends \
        postgresql-client \
        libxml2 \
        gosu \
        openssh-client \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /tmp/pgbackrest-release/src/pgbackrest /usr/bin/pgbackrest

RUN groupadd --gid ${BACKREST_GID} ${BACKREST_GROUP} \
    && useradd --shell /bin/bash --uid ${BACKREST_UID} --gid ${BACKREST_GID} -m ${BACKREST_USER} \
    && mkdir -p -m 755 /etc/bash_completion.d \
    && mkdir -p -m 750 /var/log/pgbackrest \
        /var/lib/pgbackrest \
        /var/spool/pgbackrest \
        /etc/pgbackrest \
        /etc/pgbackrest/conf.d \
    && touch /etc/pgbackrest/pgbackrest.conf \
    && chmod 640 /etc/pgbackrest/pgbackrest.conf \
    && chown -R ${BACKREST_USER}:${BACKREST_GROUP} \
        /var/log/pgbackrest \
        /var/lib/pgbackrest \
        /var/spool/pgbackrest \
        /etc/pgbackrest \
    && cp /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo "${TZ}" > /etc/timezone

COPY --chmod=755 files/entrypoint.sh /entrypoint.sh
COPY --from=builder /tmp/pgbackrest-bash-completion/pgbackrest-completion.sh /etc/bash_completion.d

LABEL \
    org.opencontainers.image.version="${REPO_BUILD_TAG}" \
    org.opencontainers.image.source="https://github.com/woblerr/docker-pgbackrest"

ENTRYPOINT ["/entrypoint.sh"]

CMD ["pgbackrest", "version"]