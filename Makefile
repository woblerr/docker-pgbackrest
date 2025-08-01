BACKREST_VERSIONS = 2.54.1 2.54.2 2.55.0 2.55.1 2.56.0
TAG?=2.56.0
TAG_MESON_BUILD=2.51
BACKREST_DOWNLOAD_URL = https://github.com/pgbackrest/pgbackrest/archive/release
BACKREST_GPDB_VERSIONS = 2.47_arenadata4 2.50_arenadata4 2.52_arenadata9
TAG_GPDB?=2.52_arenadata9
BACKREST_GPDB_DOWNLOAD_URL = https://github.com/arenadata/pgbackrest/archive
BACKREST_COMP_VERSION?=v0.11
BACKREST_OLD_COMP_VERSION?=v0.10
TAG_BACKREST_OLD_COMP_VERSION?=2.56.0
UID := $(shell id -u)
GID := $(shell id -g)


all: $(BACKREST_VERSIONS) $(addsuffix -alpine,$(BACKREST_VERSIONS)) $(BACKREST_GPDB_VERSIONS) $(addsuffix -alpine,$(BACKREST_GPDB_VERSIONS))

.PHONY: $(BACKREST_VERSIONS)
$(BACKREST_VERSIONS):
	$(call get_completion_version,COMP_VERSION,$@)
	@echo "Build pgbackrest:$@ docker image"
	docker build --pull -f Dockerfile --build-arg BACKREST_VERSION=$@ --build-arg BACKREST_COMPLETION_VERSION=$(COMP_VERSION) --build-arg BACKREST_DOWNLOAD_URL=$(BACKREST_DOWNLOAD_URL) -t pgbackrest:$@ .
	docker run pgbackrest:$@

.PHONY: build_version
build_version:
	$(call get_completion_version,COMP_VERSION,$(TAG))
	$(eval IS_MAKE_BUILD := $(call version_compare,$(TAG),$(TAG_MESON_BUILD)))
	@echo "Build pgbackrest:$(TAG) docker image"
	if [ "$(IS_MAKE_BUILD)" = "true" ]; then \
		docker build --pull -f Dockerfile_make --build-arg BACKREST_VERSION=$(TAG) --build-arg BACKREST_COMPLETION_VERSION=$(COMP_VERSION) --build-arg BACKREST_DOWNLOAD_URL=$(BACKREST_DOWNLOAD_URL) -t pgbackrest:$(TAG) . ; \
	else \
		docker build --pull -f Dockerfile --build-arg BACKREST_VERSION=$(TAG) --build-arg BACKREST_COMPLETION_VERSION=$(COMP_VERSION) --build-arg BACKREST_DOWNLOAD_URL=$(BACKREST_DOWNLOAD_URL) -t pgbackrest:$(TAG) . ; \
	fi
	@docker run pgbackrest:$(TAG)

.PHONY: $(BACKREST_GPDB_VERSIONS)
$(BACKREST_GPDB_VERSIONS):
	$(call gpdb_image_tag,IMAGE_TAG,$@)
	$(call get_completion_version,COMP_VERSION,$@)
	@echo "Build pgbackrest:$(IMAGE_TAG) docker image"
	docker build --pull -f Dockerfile_make --build-arg BACKREST_VERSION=$@ --build-arg BACKREST_COMPLETION_VERSION=$(COMP_VERSION) --build-arg BACKREST_DOWNLOAD_URL=$(BACKREST_GPDB_DOWNLOAD_URL) -t pgbackrest:$(IMAGE_TAG) .
	docker run pgbackrest:$(IMAGE_TAG)

.PHONY: build_version_gpdb
build_version_gpdb:
	$(call gpdb_image_tag,IMAGE_TAG,$(TAG_GPDB))
	$(call get_completion_version,COMP_VERSION,$(TAG_GPDB))
	@echo "Build pgbackrest:$(IMAGE_TAG) docker image"
	docker build --pull -f Dockerfile_make --build-arg BACKREST_VERSION=$(TAG_GPDB) --build-arg BACKREST_COMPLETION_VERSION=$(COMP_VERSION) --build-arg BACKREST_DOWNLOAD_URL=$(BACKREST_GPDB_DOWNLOAD_URL) -t pgbackrest:$(IMAGE_TAG) .
	docker run pgbackrest:$(IMAGE_TAG)

.PHONY: $(BACKREST_VERSIONS)-alpine
$(addsuffix -alpine,$(BACKREST_VERSIONS)):
	$(call get_completion_version,COMP_VERSION,$(subst -alpine,,$@))
	@echo "Build pgbackrest:$@ docker image"
	docker build --pull -f Dockerfile.alpine --build-arg BACKREST_VERSION=$(subst -alpine,,$@) --build-arg BACKREST_COMPLETION_VERSION=$(COMP_VERSION) --build-arg BACKREST_DOWNLOAD_URL=$(BACKREST_DOWNLOAD_URL) -t pgbackrest:$@ .
	docker run pgbackrest:$@

.PHONY: build_version_alpine
build_version_alpine:
	$(call get_completion_version,COMP_VERSION,$(TAG))
	$(eval IS_MAKE_BUILD := $(call version_compare,$(TAG),$(TAG_MESON_BUILD)))
	@echo "Build pgbackrest:$(TAG)-alpine docker image"
	@if [ "$(IS_MAKE_BUILD)" = "true" ]; then \
		docker build --pull -f Dockerfile_make.alpine --build-arg BACKREST_VERSION=$(TAG) --build-arg BACKREST_COMPLETION_VERSION=$(COMP_VERSION) --build-arg BACKREST_DOWNLOAD_URL=$(BACKREST_DOWNLOAD_URL) -t pgbackrest:$(TAG)-alpine . ; \
	else \
		docker build --pull -f Dockerfile.alpine --build-arg BACKREST_VERSION=$(TAG) --build-arg BACKREST_COMPLETION_VERSION=$(COMP_VERSION) --build-arg BACKREST_DOWNLOAD_URL=$(BACKREST_DOWNLOAD_URL) -t pgbackrest:$(TAG)-alpine . ; \
	fi
	docker run pgbackrest:$(TAG)-alpine

.PHONY: $(BACKREST_GPDB_VERSIONS)-alpine
$(addsuffix -alpine,$(BACKREST_GPDB_VERSIONS)):
	$(call gpdb_image_tag_alpine,IMAGE_TAG,$@)
	$(call get_completion_version,COMP_VERSION,$(subst -alpine,,$@))
	@echo "Build pgbackrest:$(IMAGE_TAG) docker image"
	docker build --pull -f Dockerfile_make.alpine --build-arg BACKREST_VERSION=$(subst -alpine,,$@) --build-arg BACKREST_COMPLETION_VERSION=$(COMP_VERSION) --build-arg BACKREST_DOWNLOAD_URL=$(BACKREST_GPDB_DOWNLOAD_URL) -t pgbackrest:$(IMAGE_TAG) .
	docker run pgbackrest:$(shell echo $@ | cut -d_ -f1)-gpdb-alpine

.PHONY: build_version_gpdb_alpine
build_version_gpdb_alpine:
	$(call gpdb_image_tag_alpine,IMAGE_TAG,$(TAG_GPDB))
	$(call get_completion_version,COMP_VERSION,$(TAG_GPDB))
	@echo "Build pgbackrest:$(IMAGE_TAG) docker image"
	docker build --pull -f Dockerfile_make.alpine --build-arg BACKREST_VERSION=$(TAG_GPDB) --build-arg BACKREST_COMPLETION_VERSION=$(COMP_VERSION) --build-arg BACKREST_DOWNLOAD_URL=$(BACKREST_GPDB_DOWNLOAD_URL) -t pgbackrest:$(IMAGE_TAG) .
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
	TAG=${TAG} BACKREST_UID=$(UID) BACKREST_GID=$(GID) docker compose -f e2e_tests/docker-compose.sftp.yml -f e2e_tests/docker-compose.s3.yml -f e2e_tests/docker-compose.pg.yml up -d --build --force-recreate --always-recreate-deps pg-${1}
	@if [ "${1}" == "tls" ]; then \
		TAG=${TAG} BACKREST_UID=$(UID) BACKREST_GID=$(GID) docker compose -f e2e_tests/docker-compose.sftp.yml -f e2e_tests/docker-compose.s3.yml -f e2e_tests/docker-compose.pg.yml -f e2e_tests/docker-compose.backup-${1}.yml up -d --no-deps backup_server-${1}; \
	fi
	@sleep 30
	TAG=${TAG} BACKREST_UID=$(UID) BACKREST_GID=$(GID) docker compose -f e2e_tests/docker-compose.sftp.yml -f e2e_tests/docker-compose.s3.yml -f e2e_tests/docker-compose.pg.yml -f e2e_tests/docker-compose.backup-${1}.yml run --rm --name backup-${1} --no-deps backup-${1}
	TAG=${TAG} BACKREST_UID=$(UID) BACKREST_GID=$(GID) docker compose -f e2e_tests/docker-compose.sftp.yml -f e2e_tests/docker-compose.s3.yml -f e2e_tests/docker-compose.pg.yml -f e2e_tests/docker-compose.backup-${1}.yml run --rm --name backup_alpine-${1} --no-deps backup_alpine-${1}
endef

define down_docker_compose
	TAG=${TAG} BACKREST_UID=$(UID) BACKREST_GID=$(GID) docker compose -f e2e_tests/docker-compose.sftp.yml -f e2e_tests/docker-compose.s3.yml -f e2e_tests/docker-compose.pg.yml -f e2e_tests/docker-compose.backup-${1}.yml down -v
endef

define set_permissions
	@chmod 700 e2e_tests/conf/ssh/ e2e_tests/conf/pg/sshd/ e2e_tests/conf/sftp/sshd-rsa/ e2e_tests/conf/sftp/sshd-ed25519/ e2e_tests/conf/pgbackrest/cert/ 
	@chmod 600 e2e_tests/conf/ssh/* e2e_tests/conf/pg/sshd/* e2e_tests/conf/sftp/sshd-rsa/* e2e_tests/conf/sftp/sshd-ed25519/* e2e_tests/conf/pgbackrest/cert/*
endef

define extract_version
	$(shell echo $(1) | cut -d_ -f1)
endef

define version_compare
	$(shell ( \
		v1="$(1)"; v2="$(2)"; \
		IFS='.' read -ra V1 <<< "$$v1"; \
		IFS='.' read -ra V2 <<< "$$v2"; \
		max_len=$$(( $${#V1[@]} > $${#V2[@]} ? $${#V1[@]} : $${#V2[@]} )); \
		for (( i=0; i<max_len; i++ )); do \
			v1_part=$${V1[i]:-0}; \
			v2_part=$${V2[i]:-0}; \
			if [ "$$v1_part" -lt "$$v2_part" ] 2>/dev/null; then \
				echo "true"; exit; \
			elif [ "$$v1_part" -gt "$$v2_part" ] 2>/dev/null; then \
				echo "false"; exit; \
			fi; \
		done; \
		echo "false" \
	))
endef

define gpdb_image_tag
	$(eval $(1) := $(call extract_version,$(2))-gpdb)
endef

define gpdb_image_tag_alpine
	$(eval $(1) := $(call extract_version,$(2))-gpdb-alpine)
endef

define get_completion_version
	$(eval VERSION_NUM := $(call extract_version,$(2)))
	$(eval IS_OLD_COMP_SCRIPT := $(call version_compare,$(VERSION_NUM),$(TAG_BACKREST_OLD_COMP_VERSION)))
	$(eval $(1) := $(shell \
		if [ "$(IS_OLD_COMP_SCRIPT)" = "true" ]; then \
			echo "$(BACKREST_OLD_COMP_VERSION)"; \
		else \
			echo "$(BACKREST_COMP_VERSION)"; \
		fi \
	))
endef