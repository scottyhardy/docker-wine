default: build

run:
	./docker-wine --local

build: Dockerfile
	./build.sh ubuntu-stable

build-from-scratch:
	./build.sh ubuntu-stable '--no-cache --pull'
