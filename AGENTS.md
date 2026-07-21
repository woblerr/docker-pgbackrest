# AGENTS.md

## Project Overview

This repository builds Docker images for pgBackRest on Ubuntu and Alpine,
plus separate tags for the Arenadata/Greenplum fork.
The main runtime surface is `files/entrypoint.sh`,
which runs commands as the configured non-root pgBackRest user
and can start `pgbackrest server` for TLS modes.

The build system is Makefile, Dockerfiles, and GitHub Actions.
There is no language package manager, unit-test framework, or lint target in this repo.

## Project Structure

- `Dockerfile` and `Dockerfile.alpine` are the default upstream pgBackRest image builds.
- `Dockerfile_source_archive` and `Dockerfile_source_archive.alpine` build pgBackRest from GitHub source archives.
- `Dockerfile_make` and `Dockerfile_make.alpine` are for pgBackRest versions before the Meson build system.
- `files/entrypoint.sh` controls user/group setup and TLS server startup modes.
- `e2e_tests/` contains docker compose integration tests, fixtures, certificates,
  SSH/SFTP keys, and PostgreSQL test images.
- `.github/workflows/build.yml` is the CI build and publish workflow.

## Build Commands

Prefer Makefile targets over raw `docker build` commands.

```bash
make build_version TAG=2.59.0
make build_version_alpine TAG=2.59.0
make build_version_gpdb
make build_version_gpdb_alpine
```

Use `make -n <target>` when validating Makefile routing without building images.
These targets run Docker builds, pull base images, download pgBackRest sources,
and then run the built image.

## Version Build Routing

Keep the Dockerfile routing consistent across `Makefile`, `.github/workflows/build.yml`, and `README.md`.

- pgBackRest versions `< 2.51` use `Dockerfile_make*`.
- pgBackRest versions `>= 2.51` and `< 2.59.0` use `Dockerfile_source_archive*`
  with `https://github.com/pgbackrest/pgbackrest/archive/release`.
- pgBackRest versions `>= 2.59.0` use the default `Dockerfile*`
  with `https://github.com/pgbackrest/pgbackrest/releases/download/release`.
- GPDB fork builds use `Dockerfile_source_archive*` because their download URL
  is a GitHub source archive from `https://github.com/arenadata/pgbackrest/archive`.

Use `BACKREST_DOWNLOAD_URL` for both upstream distribution tarballs and GitHub source archives.
Select the URL together with the Dockerfile route.

## Completion Version Routing

`pgbackrest-bash-completion` versions are tied to pgBackRest versions:

- pgBackRest versions `< 2.56.0` use completion script `v0.10`.
- pgBackRest versions `>= 2.56.0` use completion script `v0.11`.

Keep this routing synchronized between `BACKREST_COMP_VERSION`, `BACKREST_OLD_COMP_VERSION`,
and `TAG_BACKREST_OLD_COMP_VERSION` in `Makefile`,
and the `pgbackrest_completion_*` variables in `.github/workflows/build.yml`.
When README build examples include `BACKREST_COMPLETION_VERSION`,
keep those examples consistent with the routing.
Do not add a separate README compatibility note unless the user explicitly asks for it.

## Release Updates

When adding a new upstream pgBackRest version, update all synchronized surfaces:

- `BACKREST_VERSIONS`, `TAG`, completion version variables, and any build threshold variables in `Makefile`.
- The upstream matrix, `latest_version`, and completion version variables in `.github/workflows/build.yml`.
- Supported tags and examples in `README.md`.
- `e2e_tests/.env`.
- Default `BACKREST_VERSION` args in `e2e_tests/conf/pg/Dockerfile` and `e2e_tests/conf/sftp/Dockerfile`.

Do not mix upstream pgBackRest updates with GPDB fork updates in the same PR or task
unless the user explicitly asks for both.
Upstream pgBackRest and the Arenadata/Greenplum fork have separate version lists,
download URLs, image tags, and compatibility risks,
so they should be reviewed and tested independently.

## GPDB Updates

When updating the GPDB fork, keep the change scoped to GPDB surfaces:

- Update `BACKREST_GPDB_VERSIONS` and `TAG_GPDB` in `Makefile`.
- Update the GPDB matrix in `.github/workflows/build.yml`.
- Update the GPDB supported tags and examples in `README.md`.
- Keep `BACKREST_GPDB_DOWNLOAD_URL` pointed at
  `https://github.com/arenadata/pgbackrest/archive` unless the fork changes its packaging.
- Keep GPDB builds on `Dockerfile_source_archive*` for Meson versions and `Dockerfile_make*` for versions before `2.51`.

Verify GPDB routing with:

```bash
make -n build_version_gpdb
make -n build_version_gpdb_alpine
```

When practical, build and run both GPDB images:

```bash
make build_version_gpdb
make build_version_gpdb_alpine
```

## End-to-End Tests

E2E tests require Docker Compose and start MinIO, nginx, SFTP, PostgreSQL,
and pgBackRest containers.
They also run cleanup with `docker compose ... down -v`, which removes compose volumes.

```bash
make test-e2e
make test-e2e-ssh
make test-e2e-tls
make test-e2e-down
```

Ask before running e2e targets unless the user explicitly requested them.
Use `make -n test-e2e-ssh` or `make -n test-e2e-tls`
to inspect the compose commands without starting services.

## Runtime Patterns

`BACKREST_TLS_SERVER=enable` makes the entrypoint `exec pgbackrest server` in the foreground.
`BACKREST_HOST_TYPE=tls` starts `pgbackrest server` in the background,
sleeps for `BACKREST_TLS_WAIT`, checks the process with `ps`,
and then runs the requested command.

These Docker images intentionally do not compile pgBackRest with systemd notify support.
The documented startup modes are Docker entrypoint modes, not systemd service modes.

## Verification

For Dockerfile or build-routing changes, verify the relevant dry-runs and, when practical, real image builds:

```bash
make -n build_version TAG=2.58.0
make -n build_version TAG=2.59.0
make -n build_version_alpine TAG=2.58.0
make -n build_version_alpine TAG=2.59.0
make -n build_version_gpdb
make -n build_version_gpdb_alpine
```

After building, check:

```bash
docker run --rm pgbackrest:2.59.0 pgbackrest version
docker run --rm pgbackrest:2.59.0-alpine pgbackrest version
```

Always run `git diff --check` before handing off changes.

## Editing These Notes

Keep this file operational, not a second README.
Use semantic line breaks where practical so future diffs stay small.
Document only repository-specific rules that future agents can verify from this repo.
