SERVER := ci1.artifactory.cm.volvocars.biz:5006
REPO := core_docker
ARTIFACT := raspberry_crosscompile

all:
	@echo $(SERVER)/$(REPO)/$(ARTIFACT)

docker-build:
	docker build -t $(REPO)/$(ARTIFACT) .

docker-tag:
	docker tag $(REPO)/$(ARTIFACT) $(SERVER)/$(REPO)/$(ARTIFACT)

docker-push: docker-tag
	docker push $(SERVER)/$(REPO)/$(ARTIFACT)

docker-login:
	docker login $(SERVER)/$(REPO)

