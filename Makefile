.PHONY: docker_build
docker_build:
	docker build . -t flipbit03/ankane-dexter:latest

.PHONY: docker_publish
docker_publish: docker_build
	docker push flipbit03/ankane-dexter:latest
	