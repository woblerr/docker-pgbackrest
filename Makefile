BACKREST_VERSIONS = 2.36 2.37 2.38 2.39 2.40
TAG?=2.40
BACKREST_COMP_VERSION?=v0.7
UID := $(shell id -u)
GID := $(shell id -g)

all: $(BACKREST_VERSIONS) $(addsuffix -alpine,$(BACKREST_VERSIONS))

.PHONY: $(BACKREST_VERSIONS)
$(BACKREST_VERSIONS):
	@echo "Build pgbackrest:$@ docker image"
	docker build --pull -f Dockerfile --build-arg BACKREST_VERSION=$@ --build-arg BACKREST_COMPLETION_VERSION=$(BACKREST_COMP_VERSION) -t pgbackrest:$@ .
	docker run pgbackrest:$@

.PHONY: build_version
build_version:
	@echo "Build pgbackrest:$(TAG) docker image"
	docker build --pull -f Dockerfile --build-arg BACKREST_VERSION=$(TAG) --build-arg BACKREST_COMPLETION_VERSION=$(BACKREST_COMP_VERSION) -t pgbackrest:$(TAG) .
	docker run pgbackrest:$(TAG)

.PHONY: $(BACKREST_VERSIONS)-alpine
$(addsuffix -alpine,$(BACKREST_VERSIONS)):
	@echo "Build pgbackrest:$@ docker image"
	docker build --pull -f Dockerfile.alpine --build-arg BACKREST_VERSION=$(subst -alpine,,$@) --build-arg BACKREST_COMPLETION_VERSION=$(BACKREST_COMP_VERSION) -t pgbackrest:$@ .
	docker run pgbackrest:$@

.PHONY: build_version_alpine
build_version_alpine:
	@echo "Build pgbackrest:$(TAG)-alpine docker image"
	docker build --pull -f Dockerfile.alpine --build-arg BACKREST_VERSION=$(TAG) --build-arg BACKREST_COMPLETION_VERSION=$(BACKREST_COMP_VERSION) -t pgbackrest:$(TAG)-alpine .
	docker run pgbackrest:$(TAG)-alpine

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
