default: build 

run:
	./docker-wine

build: Dockerfile
	docker build \
		--build-arg BUILD_DATE=$$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
		--build-arg GIT_REV=$$(git rev-parse HEAD) \
		-t docker-wine .
