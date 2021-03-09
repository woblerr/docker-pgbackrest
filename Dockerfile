FROM ubuntu:20.04 AS builder

ARG BACKREST_VERSION

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

RUN wget https://github.com/pgbackrest/pgbackrest/archive/release/${BACKREST_VERSION}.tar.gz -O /tmp/${BACKREST_VERSION}.tar.gz \
    && tar -xzf /tmp/${BACKREST_VERSION}.tar.gz -C /tmp \
    && mv /tmp/pgbackrest-release-${BACKREST_VERSION} /tmp/pgbackrest-release \
    && cd /tmp/pgbackrest-release/src \
    && ./configure \
    && make

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
COPY files/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh \
    && groupadd --gid ${BACKREST_GID} ${BACKREST_GROUP} \
    && useradd --uid ${BACKREST_UID} --gid ${BACKREST_GID} -m ${BACKREST_USER} \
    && mkdir -p -m 755 /var/log/pgbackrest \
    && mkdir -p -m 755 /etc/pgbackrest/conf.d \
    && touch /etc/pgbackrest/pgbackrest.conf \
    && chmod 644 /etc/pgbackrest/pgbackrest.conf \
    && chown -R ${BACKREST_USER}:${BACKREST_GROUP} \
        /var/log/pgbackrest \
        /etc/pgbackrest\
    && cp /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo "${TZ}" > /etc/timezone

 LABEL \
    org.opencontainers.image.version="${REPO_BUILD_TAG}" \
    org.opencontainers.image.source="https://github.com/woblerr/docker-pgbackrest"

ENTRYPOINT ["/entrypoint.sh"]

CMD ["pgbackrest", "version"]