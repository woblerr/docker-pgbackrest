# docker-pgbackrest

[![Actions Status](https://github.com/woblerr/docker-pgbackrest/workflows/build/badge.svg)](https://github.com/woblerr/docker-pgbackrest/actions)

[pgBackRest](https://pgbackrest.org/) inside Docker can be useful for refusing to install pgBackRest as a system package (using yum or apt, for example) on your [Dedicated Repository Host](https://pgbackrest.org/user-guide.html#repo-host) or inside CI/CD systems. You can just run pgBackRest in Docker. At the same time, the PostgreSQL server side must be configured according to the pgBackRest documentation.

The repository contains information for the last 5 releases of pgBackRest. If necessary to use an older version -  do a [manual build](#build).

Supported pgBackRest version tags:

* `2.54.0`, `latest`
* `2.54.0-alpine`
* `2.53.1`
* `2.53.1-alpine`
* `2.53`
* `2.53-alpine`
* `2.52.1`
* `2.52.1-alpine`
* `2.52`
* `2.52-alpine`

The repository also contains information for releases of pgBackRest fork with Greenplum support (see [pgbackrest/pull/1833](https://github.com/pgbackrest/pgbackrest/pull/1833)). Details - [build with Greenplum support](#build-with-greenplum-support).

The repository contains information for the last 3 releases of pgBackRest fork with Greenplum support. If necessary to use an older version - do a [manual build](#build).

Supported pgBackRest version tags with Greenplum support:
* `2.52-gpdb`
* `2.52-gpdb-alpine`
* `2.50-gpdb`
* `2.50-gpdb-alpine`
* `2.47-gpdb`
* `2.47-gpdb-alpine`

The image is based on the official ubuntu or alpine image. For ubuntu image each version of pgBackRest builds from the source code in a separate `builder` container. For alpine image each version of pgBackRest builds from the source code in container using virtual package `.backrest-build`.

The image contains [pgbackrest-bash-completion](https://github.com/woblerr/pgbackrest-bash-completion) script. You can complete `pgbackrest` commands by pressing tab key.

Environment variables supported by this image:

* `TZ` - container's time zone, default `Etc/UTC`;
* `BACKREST_USER` - non-root user name for execution of the command, default `pgbackrest`;
* `BACKREST_UID` - UID of internal `${BACKREST_USER}` user, default `2001`;
* `BACKREST_GROUP` - group name of internal `${BACKREST_USER}` user, default `pgbackrest`;
* `BACKREST_GID` - GID of internal `${BACKREST_USER}` user, default `2001`;
* `BACKREST_HOST_TYPE` - repository host protocol type, default `ssh`, available values: `ssh`, `tls`;
* `BACKREST_TLS_WAIT` - waiting for TLS server startup in seconds when `BACKREST_HOST_TYPE=tls`, default `15`;
* `BACKREST_TLS_SERVER` - start container as pgBackRest TLS server, default `disable`, available values: `disable`, `enable`.

## Pull

Change `tag` to to the version you need.

* Docker Hub:

```bash
docker pull woblerr/pgbackrest:tag
```

```bash
docker pull woblerr/pgbackrest:tag-alpine
```

* GitHub Registry:

```bash
docker pull ghcr.io/woblerr/pgbackrest:tag
```

```bash
docker pull ghcr.io/woblerr/pgbackrest:tag-alpine
```

## Run

You will need to mount the necessary directories or files inside the container (or use this image to build your own on top of it).

### Simple

```bash
docker run --rm  pgbackrest:51 pgbackrest help
```

### Injecting inside

```bash
docker run --rm -it pgbackrest:2.54.0 bash

pgbackrest@cac1f58b56f2:/$ pgbackrest version
pgBackRest 2.54.0
```

### Example for Dedicated Repository Host

Host `USER:GROUP` - `pgbackrest:pgbackrest`, `UID:GID` - `1001:1001`. Backups are stored locally under the user `pgbackrest`.

#### Use SSH

```bash
docker run --rm \
    -e BACKREST_UID=1001 \
    -e BACKREST_GID=1001 \
    -v ~/.ssh/id_rsa:/home/pgbackrest/.ssh/id_rsa \
    -v /etc/pgbackrest:/etc/pgbackrest \
    -v /var/lib/pgbackrest:/var/lib/pgbackrest \
    pgbackrest:2.54.0 \
    pgbackrest backup --stanza demo --type full --log-level-console info
```

And and the same time for old pgBackRest version:

```bash
docker run --rm \
    -e BACKREST_UID=1001 \
    -e BACKREST_GID=1001 \
    -v ~/.ssh/id_rsa:/home/pgbackrest/.ssh/id_rsa \
    -v /etc/pgbackrest:/etc/pgbackrest \
    -v /var/lib/pgbackrest:/var/lib/pgbackrest \
    pgbackrest:2.30 \
    pgbackrest backup --stanza demo-old --type full --log-level-console info
```

To exclude simultaneous execution of multiple backup processes for one stanza:

```bash
docker run --rm \
    -e BACKREST_UID=1001 \
    -e BACKREST_GID=1001 \
    -v ~/.ssh/id_rsa:/home/pgbackrest/.ssh/id_rsa \
    -v /etc/pgbackrest:/etc/pgbackrest \
    -v /var/lib/pgbackrest:/var/lib/pgbackrest \
    -v /tmp/pgbackrest:/tmp/pgbackrest \
    pgbackrest:2.54.0 \
    pgbackrest backup --stanza demo --type full --log-level-console info
```

#### Use TLS

Available only for `pgBackRest version >= 2.37`.

There are two mode for using TLS for communication.
* Run container as pgBackRest TLS server.
  
  You need to set `BACKREST_TLS_SERVER=enable`.

  The variables `BACKREST_HOST_TYPE` and `BACKREST_TLS_WAIT` do not affect this startup mode.

* Run container with TLS server in background for pgBackRest execution over TLS.
  
  You need to set `BACKREST_HOST_TYPE=tls`.

  Using `BACKREST_TLS_WAIT`, you can change the TLS server startup waiting. By default, checking that the TLS server is running will be performed after `15 seconds`.

  The variable should be `BACKREST_TLS_SERVER=disable`.

TLS server configuration is described in the [pgBackRest documentation](https://pgbackrest.org/user-guide-rhel.html#repo-host/config).

##### Run container as pgBackRest TLS server

```bash
docker run -d \
    -e BACKREST_UID=1001 \
    -e BACKREST_GID=1001 \
    -e BACKREST_TLS_SERVER=enable \
    -v /etc/pgbackrest:/etc/pgbackrest \
    -v /var/lib/pgbackrest:/var/lib/pgbackrest \
    -p 8432:8432 \
    --name backrest_server \
    pgbackrest:2.54.0
```

##### Run container with TLS server in background for pgBackRest execution over TLS

```bash
docker run --rm \
    -e BACKREST_UID=1001 \
    -e BACKREST_GID=1001 \
    -e BACKREST_HOST_TYPE=tls \
    -v /etc/pgbackrest:/etc/pgbackrest \
    -v /var/lib/pgbackrest:/var/lib/pgbackrest \
    pgbackrest:2.54.0 \
    pgbackrest backup --stanza demo --type full --log-level-console info
```

### Example for backup to local path for PostgreSQL running locally in Chicago

PostgreSQL run from user `postgres:postgres` with UID:GID `1001:1001`. PostgreSQL data path - `/var/lib/postgresql/12/main`, pgBackRest backup path - `/var/lib/pgbackrest`.

```bash
docker run --rm \
    -e BACKREST_USER=postgres \
    -e BACKREST_UID=1001 \
    -e BACKREST_GROUP=postgres \
    -e BACKREST_GID=1001 \
    -e TZ=America/Chicago \
    -v /etc/pgbackrest/pgbackrest.conf:/etc/pgbackrest/pgbackrest.conf \
    -v /var/lib/postgresql/12/main:/var/lib/postgresql/12/main \
    -v /var/lib/pgbackrest:/var/lib/pgbackrest \
    -v /var/run/postgresql/.s.PGSQL.5432:/var/run/postgresql/.s.PGSQL.5432 \
    pgbackrest:2.54.0 \
    pgbackrest backup --stanza demo --type full --log-level-console info
```

### Example for backup to local path for PostgreSQL running remote over TLS

PostgreSQL run on remote host. Сommunication between hosts via TLS. pgBackRest path for backup and WAL files - `/var/lib/pgbackrest`.

Run the container as a TLS server. After that, remote PostgreSQL will be able to archive WAL files.

```bash
docker run -d \
    -e BACKREST_UID=1001 \
    -e BACKREST_GID=1001 \
    -e BACKREST_TLS_SERVER=enable \
    -v /etc/pgbackrest/pgbackrest.conf:/etc/pgbackrest/pgbackrest.conf \
    -v /etc/pgbackrest/cert:/etc/pgbackrest/cert \
    -v /var/lib/pgbackrest:/var/lib/pgbackrest \
    -p 8432:8432 \
    --name backrest_server \
    pgbackrest:2.54.0
```

Performing a backup:

```bash
docker run --rm \
    -e BACKREST_UID=1001 \
    -e BACKREST_GID=1001 \
    -e BACKREST_HOST_TYPE=tls \
    -v /etc/pgbackrest/pgbackrest.conf:/etc/pgbackrest/pgbackrest.conf \
    -v /etc/pgbackrest/cert:/etc/pgbackrest/cert \
    -v /var/lib/pgbackrest:/var/lib/pgbackrest \
    pgbackrest:2.54.0 \
    pgbackrest backup --stanza demo --type full --log-level-console info
```

## Build

```bash
make build_version TAG=2.54.0
```

```bash
make build_version_alpine TAG=2.54.0
```

or

```bash
docker build -f Dockerfile --build-arg BACKREST_VERSION=2.54.0 --build-arg BACKREST_COMPLETION_VERSION=v0.9 -t pgbackrest:2.54.0 .
```

```bash
docker build -f Dockerfile.alpine --build-arg BACKREST_VERSION=2.54.0 --build-arg BACKREST_COMPLETION_VERSION=v0.9 -t pgbackrest:2.54.0-alpine .
```

### Build pgBackRest < `v2.51`

Since version `v2.51`, the build system for pgBackRest is `meson`. The `autoconf/make` build will not receive any new features and will be removed in future. If you need to build pgBackRest lower than `v2.51`, use the files [Dockerfile_make](./Dockerfile) or [Dockerfile_make.alpine](./Dockerfile_make.alpine).

```bash
make build_version TAG=2.49
```

```bash
make build_version_alpine TAG=2.49
```

or

```bash
docker build -f Dockerfile_make --build-arg BACKREST_VERSION=2.49 --build-arg BACKREST_COMPLETION_VERSION=v0.9 -t pgbackrest:2.49 .
```

```bash
docker build -f Dockerfile_make.alpine --build-arg BACKREST_VERSION=2.49 --build-arg BACKREST_COMPLETION_VERSION=v0.9 -t pgbackrest:2.49-alpine .
```

## Build with Greenplum support

PR [pgbackrest/pull/1833](https://github.com/pgbackrest/pgbackrest/pull/1833) is still not merged into pgBackRest. The separate tags `*-gpdb` are used for pgBackRest images with Greenplum support. When the PR is accepted, separate tags will no longer be needed.

The image completely repeats all the possibilities of the image for pgBackRest.

### Pull

Change `tag` to to the version you need.

* Docker Hub:

```bash
docker pull woblerr/pgbackrest:tag-gpdb
```

```bash
docker pull woblerr/pgbackrest:tag-gpdb-alpine
```

* GitHub Registry:

```bash
docker pull ghcr.io/woblerr/pgbackrest:tag-gpdb
```

```bash
docker pull ghcr.io/woblerr/pgbackrest:tag-gpdb-alpine
```

### Run

```bash
docker run --rm  pgbackrest:2.52-gpdb pgbackrest help
```

## Running tests

Run the end-to-end tests:

```bash
make test-e2e
```

See [tests description](./e2e_tests/README.md).