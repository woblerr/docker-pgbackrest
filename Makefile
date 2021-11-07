BACKREST_VERSIONS = 2.31 2.32 2.33 2.34 2.35
TAG?=2.35
BACKREST_COMP_VERSION?=v0.4

all: $(BACKREST_VERSIONS)

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
