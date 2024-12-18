BACKREST_VERSIONS = 2.52.1 2.53 2.53.1 2.54.0 2.54.1
TAG?=2.54.1
TAG_MESON_BUILD=2.51
BACKREST_DOWNLOAD_URL = https://github.com/pgbackrest/pgbackrest/archive/release
BACKREST_GPDB_VERSIONS = 2.47_arenadata4 2.50_arenadata4 2.52_arenadata7
TAG_GPDB?=2.52_arenadata7
BACKREST_GPDB_DOWNLOAD_URL = https://github.com/arenadata/pgbackrest/archive
BACKREST_COMP_VERSION?=v0.9
UID := $(shell id -u)
GID := $(shell id -g)

all: $(BACKREST_VERSIONS) $(addsuffix -alpine,$(BACKREST_VERSIONS)) $(BACKREST_GPDB_VERSIONS) $(addsuffix -alpine,$(BACKREST_GPDB_VERSIONS))

.PHONY: $(BACKREST_VERSIONS)
$(BACKREST_VERSIONS):
	@echo "Build pgbackrest:$@ docker image"
	docker build --pull -f Dockerfile --build-arg BACKREST_VERSION=$@ --build-arg BACKREST_COMPLETION_VERSION=$(BACKREST_COMP_VERSION) --build-arg BACKREST_DOWNLOAD_URL=$(BACKREST_DOWNLOAD_URL) -t pgbackrest:$@ .
	docker run pgbackrest:$@

.PHONY: build_version
build_version:
	@echo "Build pgbackrest:$(TAG) docker image"
	@if [ "${TAG}" \< "${TAG_MESON_BUILD}" ]; then \
		docker build --pull -f Dockerfile_make --build-arg BACKREST_VERSION=$(TAG) --build-arg BACKREST_COMPLETION_VERSION=$(BACKREST_COMP_VERSION) --build-arg BACKREST_DOWNLOAD_URL=$(BACKREST_DOWNLOAD_URL) -t pgbackrest:$(TAG) . ; \
	else \
		docker build --pull -f Dockerfile --build-arg BACKREST_VERSION=$(TAG) --build-arg BACKREST_COMPLETION_VERSION=$(BACKREST_COMP_VERSION) --build-arg BACKREST_DOWNLOAD_URL=$(BACKREST_DOWNLOAD_URL) -t pgbackrest:$(TAG) . ; \
	fi
	docker run pgbackrest:$(TAG)

.PHONY: $(BACKREST_GPDB_VERSIONS)
$(BACKREST_GPDB_VERSIONS):
	$(call gpdb_image_tag,IMAGE_TAG,$@)
	@echo "Build pgbackrest:$(IMAGE_TAG) docker image"
	docker build --pull -f Dockerfile_make --build-arg BACKREST_VERSION=$@ --build-arg BACKREST_COMPLETION_VERSION=$(BACKREST_COMP_VERSION) --build-arg BACKREST_DOWNLOAD_URL=$(BACKREST_GPDB_DOWNLOAD_URL) -t pgbackrest:$(IMAGE_TAG) .
	docker run pgbackrest:$(IMAGE_TAG)

.PHONY: build_version_gpdb
build_version_gpdb:
	$(call gpdb_image_tag,IMAGE_TAG,$(TAG_GPDB))
	@echo "Build pgbackrest:$(IMAGE_TAG) docker image"
	docker build --pull -f Dockerfile_make --build-arg BACKREST_VERSION=$(TAG_GPDB) --build-arg BACKREST_COMPLETION_VERSION=$(BACKREST_COMP_VERSION) --build-arg BACKREST_DOWNLOAD_URL=$(BACKREST_GPDB_DOWNLOAD_URL) -t pgbackrest:$(IMAGE_TAG) .
	docker run pgbackrest:$(IMAGE_TAG)

.PHONY: $(BACKREST_VERSIONS)-alpine
$(addsuffix -alpine,$(BACKREST_VERSIONS)):
	@echo "Build pgbackrest:$@ docker image"
	docker build --pull -f Dockerfile.alpine --build-arg BACKREST_VERSION=$(subst -alpine,,$@) --build-arg BACKREST_COMPLETION_VERSION=$(BACKREST_COMP_VERSION) --build-arg BACKREST_DOWNLOAD_URL=$(BACKREST_DOWNLOAD_URL) -t pgbackrest:$@ .
	docker run pgbackrest:$@

.PHONY: build_version_alpine
build_version_alpine:
	@echo "Build pgbackrest:$(TAG)-alpine docker image"
	@if [ "${TAG}" \< "${TAG_MESON_BUILD}" ]; then \
		docker build --pull -f Dockerfile_make.alpine --build-arg BACKREST_VERSION=$(TAG) --build-arg BACKREST_COMPLETION_VERSION=$(BACKREST_COMP_VERSION) --build-arg BACKREST_DOWNLOAD_URL=$(BACKREST_DOWNLOAD_URL) -t pgbackrest:$(TAG)-alpine . ; \
	else \
		docker build --pull -f Dockerfile.alpine --build-arg BACKREST_VERSION=$(TAG) --build-arg BACKREST_COMPLETION_VERSION=$(BACKREST_COMP_VERSION) --build-arg BACKREST_DOWNLOAD_URL=$(BACKREST_DOWNLOAD_URL) -t pgbackrest:$(TAG)-alpine . ; \
	fi
	docker run pgbackrest:$(TAG)-alpine

.PHONY: $(BACKREST_GPDB_VERSIONS)-alpine
$(addsuffix -alpine,$(BACKREST_GPDB_VERSIONS)):
	$(call gpdb_image_tag_alpine,IMAGE_TAG,$@)
	@echo "Build pgbackrest:$(IMAGE_TAG) docker image"
	docker build --pull -f Dockerfile_make.alpine --build-arg BACKREST_VERSION=$(subst -alpine,,$@) --build-arg BACKREST_COMPLETION_VERSION=$(BACKREST_COMP_VERSION) --build-arg BACKREST_DOWNLOAD_URL=$(BACKREST_GPDB_DOWNLOAD_URL) -t pgbackrest:$(IMAGE_TAG) .
	docker run pgbackrest:$(shell echo $@ | cut -d_ -f1)-gpdb-alpine

.PHONY: build_version_gpdb_alpine
build_version_gpdb_alpine:
	$(call gpdb_image_tag_alpine,IMAGE_TAG,$(TAG_GPDB))
	@echo "Build pgbackrest:$(IMAGE_TAG) docker image"
	docker build --pull -f Dockerfile_make.alpine --build-arg BACKREST_VERSION=$(TAG_GPDB) --build-arg BACKREST_COMPLETION_VERSION=$(BACKREST_COMP_VERSION) --build-arg BACKREST_DOWNLOAD_URL=$(BACKREST_GPDB_DOWNLOAD_URL) -t pgbackrest:$(IMAGE_TAG) .
	fi
	docker run pgbackrest:$(IMAGE_TAG)

.PHONY: test-e2e
test-e2e:
	@echo "Run end-to-end tests"
	make build_version
	make build_version_alpine
	make test-e2e-ssh
	make test-e2e-tls

.PHONY: test-e2e-ssh
test-e2e-ssh:
	@echo "Run end-to-end tests for SSH communication"
	$(call down_docker_compose,ssh)
	$(call run_docker_compose,ssh)
	$(call down_docker_compose,ssh)

.PHONY: test-e2e-tls
test-e2e-tls:
	@echo "Run end-to-end tests for TLS communication"
	$(call down_docker_compose,tls)
	$(call run_docker_compose,tls)
	$(call down_docker_compose,tls)

.PHONY: test-e2e-down
test-e2e-down:
	@echo "Stop old containers"
	$(call down_docker_compose,ssh)
	$(call down_docker_compose,tls)

define run_docker_compose
	$(call set_permissions)
	TAG=${TAG} BACKREST_UID=$(UID) BACKREST_GID=$(GID) docker-compose -f e2e_tests/docker-compose.sftp.yml -f e2e_tests/docker-compose.s3.yml -f e2e_tests/docker-compose.pg.yml up -d --build --force-recreate --always-recreate-deps pg-${1}
	@if [ "${1}" == "tls" ]; then \
		TAG=${TAG} BACKREST_UID=$(UID) BACKREST_GID=$(GID) docker-compose -f e2e_tests/docker-compose.sftp.yml -f e2e_tests/docker-compose.s3.yml -f e2e_tests/docker-compose.pg.yml -f e2e_tests/docker-compose.backup-${1}.yml up -d --no-deps backup_server-${1}; \
	fi
	@sleep 30
	TAG=${TAG} BACKREST_UID=$(UID) BACKREST_GID=$(GID) docker-compose -f e2e_tests/docker-compose.sftp.yml -f e2e_tests/docker-compose.s3.yml -f e2e_tests/docker-compose.pg.yml -f e2e_tests/docker-compose.backup-${1}.yml run --rm --name backup-${1} --no-deps backup-${1}
	TAG=${TAG} BACKREST_UID=$(UID) BACKREST_GID=$(GID) docker-compose -f e2e_tests/docker-compose.sftp.yml -f e2e_tests/docker-compose.s3.yml -f e2e_tests/docker-compose.pg.yml -f e2e_tests/docker-compose.backup-${1}.yml run --rm --name backup_alpine-${1} --no-deps backup_alpine-${1}
endef

define down_docker_compose
	TAG=${TAG} BACKREST_UID=$(UID) BACKREST_GID=$(GID) docker-compose -f e2e_tests/docker-compose.sftp.yml -f e2e_tests/docker-compose.s3.yml -f e2e_tests/docker-compose.pg.yml -f e2e_tests/docker-compose.backup-${1}.yml down -v
endef

define set_permissions
	@chmod 700 e2e_tests/conf/ssh/ e2e_tests/conf/pg/sshd/ e2e_tests/conf/sftp/sshd-rsa/ e2e_tests/conf/sftp/sshd-ed25519/ e2e_tests/conf/pgbackrest/cert/ 
	@chmod 600 e2e_tests/conf/ssh/* e2e_tests/conf/pg/sshd/* e2e_tests/conf/sftp/sshd-rsa/* e2e_tests/conf/sftp/sshd-ed25519/* e2e_tests/conf/pgbackrest/cert/*
endef

define gpdb_image_tag
	$(eval $(1) := $(shell echo $(2) | cut -d_ -f1)-gpdb)
endef

define gpdb_image_tag_alpine
	$(eval $(1) := $(shell echo $(2) | cut -d_ -f1)-gpdb-alpine)
endef