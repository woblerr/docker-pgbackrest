BACKREST_VERSIONS = 2.33 2.34 2.35 2.36 2.37
TAG?=2.37
BACKREST_COMP_VERSION?=v0.5
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
	BACKREST_UID=$(UID) BACKREST_GID=$(GID) docker-compose -f e2e_tests/docker-compose.yml -f e2e_tests/docker-compose.infra.yml up -d --build --force-recreate --always-recreate-deps pg
	@sleep 10
	BACKREST_UID=$(UID) BACKREST_GID=$(GID) docker-compose -f e2e_tests/docker-compose.yml -f e2e_tests/docker-compose.infra.yml run --rm --no-deps backup
	BACKREST_UID=$(UID) BACKREST_GID=$(GID) docker-compose -f e2e_tests/docker-compose.yml -f e2e_tests/docker-compose.infra.yml run --rm --no-deps backup_alpine
	BACKREST_UID=$(UID) BACKREST_GID=$(GID) docker-compose -f e2e_tests/docker-compose.yml -f e2e_tests/docker-compose.infra.yml down
	