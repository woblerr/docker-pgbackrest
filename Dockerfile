FROM ubuntu:24.04 AS builder

ARG BACKREST_VERSION
ARG BACKREST_DOWNLOAD_URL="https://github.com/pgbackrest/pgbackrest/archive/release"
ARG BACKREST_COMPLETION_VERSION
ARG BACKREST_COMPLETION_VERSION_URL="https://github.com/woblerr/pgbackrest-bash-completion/archive"

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        # According to the pgBackRest docs for v2.52, the python3-distutils package is needed for build from sources.
        # See PR https://github.com/pgbackrest/pgbackrest/pull/2338.
        # The python3-distutils package is deprecated.
        # For Meson on Ubuntu 22.04 and higher it makes sense to use the package python3-setuptools.
        # See https://ubuntu.pkgs.org/22.04/ubuntu-universe-amd64/meson_0.61.2-1_all.deb.html
        # and https://ubuntu.pkgs.org/24.04/ubuntu-universe-amd64/meson_1.3.2-1ubuntu1_all.deb.html
        # python3-distutils \
        python3-setuptools \
        gcc \
        meson \
        libpq-dev \
        libssl-dev \
        libxml2-dev \
        pkg-config \
        liblz4-dev \
        libzstd-dev \
        libbz2-dev \
        libz-dev \
        libyaml-dev \
        libssh2-1-dev \
        wget \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN wget ${BACKREST_DOWNLOAD_URL}/${BACKREST_VERSION}.tar.gz -O /tmp/pgbackrest-${BACKREST_VERSION}.tar.gz \
    && mkdir -p /tmp/pgbackrest-release /tmp/pgbackrest-build \
    && tar -xzf /tmp/pgbackrest-${BACKREST_VERSION}.tar.gz --strip-components=1 -C /tmp/pgbackrest-release \
    && meson setup /tmp/pgbackrest-build /tmp/pgbackrest-release \
    && ninja -C /tmp/pgbackrest-build

RUN wget ${BACKREST_COMPLETION_VERSION_URL}/${BACKREST_COMPLETION_VERSION}.tar.gz -O /tmp/pgbackrest-bash-completion-${BACKREST_COMPLETION_VERSION}.tar.gz \
    && tar -xzf /tmp/pgbackrest-bash-completion-${BACKREST_COMPLETION_VERSION}.tar.gz -C /tmp \
    && mv /tmp/pgbackrest-bash-completion-$(echo ${BACKREST_COMPLETION_VERSION} | tr -d v) /tmp/pgbackrest-bash-completion

FROM ubuntu:24.04

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
        libssh2-1 \
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
        /tmp/pgbackrest \
    && touch /etc/pgbackrest/pgbackrest.conf \
    && chmod 640 /etc/pgbackrest/pgbackrest.conf \
    && chown -R ${BACKREST_USER}:${BACKREST_GROUP} \
        /home/${BACKREST_USER}/.bash_completion.d \
        /var/log/pgbackrest \
        /var/lib/pgbackrest \
        /var/spool/pgbackrest \
        /etc/pgbackrest \
        /tmp/pgbackrest \
    && unlink /etc/localtime \
    && cp /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo "${TZ}" > /etc/timezone

COPY --chmod=755 files/entrypoint.sh /entrypoint.sh
COPY --from=builder --chown=${BACKREST_USER}:${BACKREST_GROUP} /tmp/pgbackrest-bash-completion/pgbackrest-completion.sh /home/${BACKREST_USER}/.bash_completion.d/pgbackrest-completion.sh
COPY --from=builder /tmp/pgbackrest-build/src/pgbackrest /usr/bin/pgbackrest

LABEL \
    org.opencontainers.image.version="${REPO_BUILD_TAG}" \
    org.opencontainers.image.source="https://github.com/woblerr/docker-pgbackrest"

ENTRYPOINT ["/entrypoint.sh"]

CMD ["pgbackrest", "version"]