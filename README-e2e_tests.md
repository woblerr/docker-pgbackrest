# End-to-end tests

The following architecture is used to run the tests.
* Separate containers for minio ang nginx. Official images [minio/minio](https://hub.docker.com/r/minio/minio/), [minio/mc](https://hub.docker.com/r/minio/mc) and [nginx](https://hub.docker.com/_/nginx) are used. It's necessary for S3 compatible storage for WAL archiving and backups.
* Separate container with PostgreSQL instance and pgBackRest for backup. It's custom image, based on docker-pgbackrest image.
* Separate container with pgBackRest. This is the `docker-pgbackrest` image.

S3 compatible storage is described in `e2e_tests/docker-compose.s3.yml`, separate container with PostgreSQL instance is described in `e2e_tests/docker-compose.pg.yml` and containers with pgBackRest for tests are described in `e2e_tests/docker-compose.yml`.

## Running tests

By default, tests are performed only for the latest supported version of pgBackRest. To run tests for a different version, you need to change the variable `TAG` in `e2e_tests/env` file and specify `TAG` variable for `make` command.

### Use SSH

```bash
make test-e2e
```

or

```bash
BACKREST_UID=$(id -u) BACKREST_GID=$(id -g) docker-compose -f e2e_tests/docker-compose.s3.yml -f e2e_tests/docker-compose.pg.yml up -d pg
BACKREST_UID=$(id -u) BACKREST_GID=$(id -g) docker-compose -f e2e_tests/docker-compose.s3.yml -f e2e_tests/docker-compose.pg.yml -f e2e_tests/docker-compose.yml run --no-deps backup
BACKREST_UID=$(id -u) BACKREST_GID=$(id -g) docker-compose -f e2e_tests/docker-compose.s3.yml -f e2e_tests/docker-compose.pg.yml -f e2e_tests/docker-compose.yml run --no-deps backup_alpine
BACKREST_UID=$(id -u) BACKREST_GID=$(id -g) docker-compose -f e2e_tests/docker-compose.s3.yml -f e2e_tests/docker-compose.pg.yml -f e2e_tests/docker-compose.yml down
```

Run tests for specific pgBackRest version:
```bash
make test-e2e TAG=2.36
```

### Use TLS

TODO.
