# End-to-end tests

The following architecture is used to run the tests.
* Separate containers for minio ang nginx. Official images [minio/minio](https://hub.docker.com/r/minio/minio/), [minio/mc](https://hub.docker.com/r/minio/mc) and [nginx](https://hub.docker.com/_/nginx) are used. It's necessary for S3 compatible storage for WAL archiving and backups.
* Separate container with PostgreSQL instance and pgBackRest for backup. It's custom image, based on docker-pgbackrest image.
* Separate container with pgBackRest. This is the `docker-pgbackrest` image.

S3 compatible storage is described in `e2e_tests/docker-compose.s3.yml`, separate container with PostgreSQL instance is described in `e2e_tests/docker-compose.pg.yml` and containers with pgBackRest for tests are described in `e2e_tests/docker-compose.backup-ssh.yml` and `e2e_tests/docker-compose.backup-tls.yml`.

## Running tests

By default, tests are performed only for the latest supported version of pgBackRest. To run tests for a different version, you need to change the variable `TAG` in `e2e_tests/env` file and specify `TAG` variable for `make` command.

```bash
make test-e2e
```

Run tests for specific pgBackRest version:
```bash
make test-e2e TAG=2.36
```

### Use SSH

```bash
make test-e2e-ssh
```

or

```bash
cd [docker-pgbackrest-root]/e2e_tests
BACKREST_UID=$(id -u) BACKREST_GID=$(id -g) docker-compose -f docker-compose.s3.yml -f docker-compose.pg.yml up -d pg-ssh
BACKREST_UID=$(id -u) BACKREST_GID=$(id -g) docker-compose -f docker-compose.s3.yml -f docker-compose.pg.yml -f docker-compose.backup-ssh.yml run --name backup-ssh --no-deps backup-ssh
BACKREST_UID=$(id -u) BACKREST_GID=$(id -g) docker-compose -f docker-compose.s3.yml -f docker-compose.pg.yml -f docker-compose.backup-ssh.yml run --name backup_alpine-ssh --no-deps backup_alpine-ssh
BACKREST_UID=$(id -u) BACKREST_GID=$(id -g) docker-compose -f docker-compose.s3.yml -f docker-compose.pg.yml -f docker-compose.backup-ssh.yml down
```

### Use TLS

TODO.

### Generate certificates

The certificates in `e2e_tests` directory are used only for end-to-end tests and are not used for actual services.

#### Nginx

```bash
cd [docker-pgbackrest-root]/e2e_tests/conf/nginx

openssl req -new -x509 -nodes -newkey rsa:4096 \
    -days 99999 \
    -subj "/CN=nginx-minio" \
    -keyout nginx-selfsigned.key \
    -out nginx-selfsigned.crt

openssl x509 -in nginx-selfsigned.crt -text -noout
```
#### pgBackRest

```bash
cd [docker-pgbackrest-root]/e2e_tests/conf/pgbackrest_certs

# Test CA
openssl genrsa -out pgbackrest-selfsigned-ca.key 4096

openssl req -new -x509 -extensions v3_ca \
    -days 99999 \
    -subj "/CN=backrest-ca" \
    -key pgbackrest-selfsigned-ca.key \
    -out pgbackrest-selfsigned-ca.crt

openssl x509 -in pgbackrest-selfsigned-ca.crt -text -noout

# Server Test Certificate
openssl genrsa -out pgbackrest-selfsigned-server.key 4096

openssl req -new -nodes \
    -out pgbackrest-selfsigned-server.csr \
    -key pgbackrest-selfsigned-server.key \
    -config pgbackrest-selfsigned-server.cnf

openssl x509 -req -extensions v3_req  -CAcreateserial \
    -days 99999 \
    -in pgbackrest-selfsigned-server.csr \
    -CA pgbackrest-selfsigned-ca.crt \
    -CAkey pgbackrest-selfsigned-ca.key \
    -out pgbackrest-selfsigned-server.crt \
    -extfile pgbackrest-selfsigned-server.cnf

openssl x509 -in pgbackrest-selfsigned-server.crt -text -noout

# Client Test Certificate
openssl genrsa -out pgbackrest-selfsigned-client.key 4096

openssl req -new -nodes \
    -out pgbackrest-selfsigned-client.csr \
    -key pgbackrest-selfsigned-client.key \
    -config pgbackrest-selfsigned-client.cnf

openssl x509 -req -extensions v3_req -CAcreateserial \
    -days 99999 \
    -in pgbackrest-selfsigned-client.csr \
    -CA pgbackrest-selfsigned-ca.crt \
    -CAkey pgbackrest-selfsigned-ca.key \
    -out pgbackrest-selfsigned-client.crt \
    -extfile pgbackrest-selfsigned-client.cnf

openssl x509 -in pgbackrest-selfsigned-client.crt -text -noout
```
