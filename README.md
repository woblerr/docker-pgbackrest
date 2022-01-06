# docker-pgbackrest

[![Actions Status](https://github.com/woblerr/docker-pgbackrest/workflows/build/badge.svg)](https://github.com/woblerr/docker-pgbackrest/actions)

[pgBackRest](https://pgbackrest.org/) inside Docker can be useful when you using [Dedicated Repository Host](https://pgbackrest.org/user-guide.html#repo-host) or inside CI/CD systems.

The repository contains information for the last 5 releases of pgBackRest. If necessary to use an older version -  do a [manual build](#build).

Supported pgBackRest version tags:

* `2.37`, `latest`
* `2.36`
* `2.35`
* `2.34`
* `2.33`

The image is based on the official ubuntu image. Each version of pgBackRest builds from the source code in a separate `builder` container.

The image contains [pgbackrest-bash-completion](https://github.com/woblerr/pgbackrest-bash-completion) script. You can complete `pgbackrest` commands by pressing tab key.

Environment variables supported by this image:

* `TZ` - container's time zone, default `Europe/Moscow`;
* `BACKREST_USER` - non-root user name for execution of the command, default `pgbackrest`;
* `BACKREST_UID` - UID of internal `${BACKREST_USER}` user, default `2001`;
* `BACKREST_GROUP` - group name of internal `${BACKREST_USER}` user, default `pgbackrest`;
* `BACKREST_GID` - GID of internal `${BACKREST_USER}` user, default `2001`.

## Pull

Change `tag` to to the version you need.

* Docker Hub:

```bash
docker pull woblerr/pgbackrest:tag
```

* GitHub Registry:

```bash
docker pull ghcr.io/woblerr/pgbackrest:tag
```

## Run

You will need to mount the necessary directories or files inside the container (or use this image to build your own on top of it).

### Simple

```bash
docker run --rm  pgbackrest:2.34 pgbackrest help
```

### Injecting inside

```bash
docker run --rm -it pgbackrest:2.34 bash

pgbackrest@cac1f58b56f2:/$ pgbackrest version
pgBackRest 2.34
```

### Example for Dedicated Repository Host

Host `USER:GROUP` - `pgbackrest:pgbackrest`, `UID:GID` - `1001:1001`. Backups are stored locally under the user `pgbackrest`.

```bash
docker run --rm \
    -e BACKREST_UID=1001 \
    -e BACKREST_GID=1001 \
    -v ~/.ssh/id_rsa:/home/pgbackrest/.ssh/id_rsa \
    -v /etc/pgbackrest:/etc/pgbackrest \
    -v /var/lib/pgbackrest:/var/lib/pgbackrest \
    pgbackrest:2.34 \
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
    pgbackrest:2.34 \
    pgbackrest backup --stanza demo --type full --log-level-console info
```

## Build

```bash
make build_version TAG=2.34
```

or

```bash
docker build -f Dockerfile --build-arg BACKREST_VERSION=2.34 --build-arg BACKREST_COMPLETION_VERSION=v0.5 -t pgbackrest:2.34 .
```
