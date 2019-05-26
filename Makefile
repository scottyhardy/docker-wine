default: build

run:
	./docker-wine --local

build: Dockerfile
	./build.sh ubuntu-stable
