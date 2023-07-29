BACKREST_VERSIONS = 2.43 2.44 2.45 2.46 2.47
TAG?=2.47
BACKREST_DOWNLOAD_URL = https://github.com/pgbackrest/pgbackrest/archive/release
BACKREST_GPDB_VERSIONS = 2.40_arenadata2 2.45_arenadata3 2.47_arenadata3
TAG_GPDB?=2.47_arenadata3
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
	docker build --pull -f Dockerfile --build-arg BACKREST_VERSION=$(TAG) --build-arg BACKREST_COMPLETION_VERSION=$(BACKREST_COMP_VERSION) --build-arg BACKREST_DOWNLOAD_URL=$(BACKREST_DOWNLOAD_URL) -t pgbackrest:$(TAG) .
	docker run pgbackrest:$(TAG)

.PHONY: $(BACKREST_GPDB_VERSIONS)
$(BACKREST_GPDB_VERSIONS):
	$(call gpdb_image_tag,IMAGE_TAG,$@)
	@echo "Build pgbackrest:$(IMAGE_TAG) docker image"
	docker build --pull -f Dockerfile --build-arg BACKREST_VERSION=$@ --build-arg BACKREST_COMPLETION_VERSION=$(BACKREST_COMP_VERSION) --build-arg BACKREST_DOWNLOAD_URL=$(BACKREST_GPDB_DOWNLOAD_URL) -t pgbackrest:$(IMAGE_TAG) .
	docker run pgbackrest:$(IMAGE_TAG)

.PHONY: build_version_gpdb
build_version_gpdb:
	$(call gpdb_image_tag,IMAGE_TAG,$(TAG_GPDB))
	@echo "Build pgbackrest:$(IMAGE_TAG) docker image"
	docker build --pull -f Dockerfile --build-arg BACKREST_VERSION=$(TAG_GPDB) --build-arg BACKREST_COMPLETION_VERSION=$(BACKREST_COMP_VERSION) --build-arg BACKREST_DOWNLOAD_URL=$(BACKREST_GPDB_DOWNLOAD_URL) -t pgbackrest:$(IMAGE_TAG) .
	docker run pgbackrest:$(IMAGE_TAG)

.PHONY: $(BACKREST_VERSIONS)-alpine
$(addsuffix -alpine,$(BACKREST_VERSIONS)):
	@echo "Build pgbackrest:$@ docker image"
	docker build --pull -f Dockerfile.alpine --build-arg BACKREST_VERSION=$(subst -alpine,,$@) --build-arg BACKREST_COMPLETION_VERSION=$(BACKREST_COMP_VERSION) --build-arg BACKREST_DOWNLOAD_URL=$(BACKREST_DOWNLOAD_URL) -t pgbackrest:$@ .
	docker run pgbackrest:$@

.PHONY: build_version_alpine
build_version_alpine:
	@echo "Build pgbackrest:$(TAG)-alpine docker image"
	docker build --pull -f Dockerfile.alpine --build-arg BACKREST_VERSION=$(TAG) --build-arg BACKREST_COMPLETION_VERSION=$(BACKREST_COMP_VERSION) --build-arg BACKREST_DOWNLOAD_URL=$(BACKREST_DOWNLOAD_URL) -t pgbackrest:$(TAG)-alpine .
	docker run pgbackrest:$(TAG)-alpine

.PHONY: $(BACKREST_GPDB_VERSIONS)-alpine
$(addsuffix -alpine,$(BACKREST_GPDB_VERSIONS)):
	$(call gpdb_image_tag_alpine,IMAGE_TAG,$@)
	@echo "Build pgbackrest:$(IMAGE_TAG) docker image"
	docker build --pull -f Dockerfile.alpine --build-arg BACKREST_VERSION=$(subst -alpine,,$@) --build-arg BACKREST_COMPLETION_VERSION=$(BACKREST_COMP_VERSION) --build-arg BACKREST_DOWNLOAD_URL=$(BACKREST_GPDB_DOWNLOAD_URL) -t pgbackrest:$(IMAGE_TAG) .
	docker run pgbackrest:$(shell echo $@ | cut -d_ -f1)-gpdb-alpine

.PHONY: build_version_gpdb_alpine
build_version_gpdb_alpine:
	$(call gpdb_image_tag_alpine,IMAGE_TAG,$(TAG_GPDB))
	@echo "Build pgbackrest:$(IMAGE_TAG) docker image"
	docker build --pull -f Dockerfile.alpine --build-arg BACKREST_VERSION=$(TAG_GPDB) --build-arg BACKREST_COMPLETION_VERSION=$(BACKREST_COMP_VERSION) --build-arg BACKREST_DOWNLOAD_URL=$(BACKREST_GPDB_DOWNLOAD_URL) -t pgbackrest:$(IMAGE_TAG) .
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
	BACKREST_UID=$(UID) BACKREST_GID=$(GID) docker-compose -f e2e_tests/docker-compose.s3.yml -f e2e_tests/docker-compose.pg.yml up -d --build --force-recreate --always-recreate-deps pg-${1}
	@if [ "${1}" == "tls" ]; then \
		BACKREST_UID=$(UID) BACKREST_GID=$(GID) docker-compose -f e2e_tests/docker-compose.s3.yml -f e2e_tests/docker-compose.pg.yml -f e2e_tests/docker-compose.backup-${1}.yml up -d --no-deps backup_server-${1}; \
	fi
	@sleep 30
	BACKREST_UID=$(UID) BACKREST_GID=$(GID) docker-compose -f e2e_tests/docker-compose.s3.yml -f e2e_tests/docker-compose.pg.yml -f e2e_tests/docker-compose.backup-${1}.yml run --rm --name backup-${1} --no-deps backup-${1}
	BACKREST_UID=$(UID) BACKREST_GID=$(GID) docker-compose -f e2e_tests/docker-compose.s3.yml -f e2e_tests/docker-compose.pg.yml -f e2e_tests/docker-compose.backup-${1}.yml run --rm --name backup_alpine-${1} --no-deps backup_alpine-${1}
endef

define down_docker_compose
	BACKREST_UID=$(UID) BACKREST_GID=$(GID) docker-compose -f e2e_tests/docker-compose.s3.yml -f e2e_tests/docker-compose.pg.yml -f e2e_tests/docker-compose.backup-${1}.yml down -v
endef

define set_permissions
	@chmod 700 e2e_tests/conf/backup/ssh/ e2e_tests/conf/pg/ssh/ e2e_tests/conf/pg/sshd/ 
	@chmod 600 e2e_tests/conf/backup/ssh/* e2e_tests/conf/pg/ssh/* e2e_tests/conf/pg/sshd/* e2e_tests/conf/pgbackrest/cert/*
endef

define gpdb_image_tag
	$(eval $(1) := $(shell echo $(2) | cut -d_ -f1)-gpdb)
endef

define gpdb_image_tag_alpine
	$(eval $(1) := $(shell echo $(2) | cut -d_ -f1)-gpdb-alpine)
endef