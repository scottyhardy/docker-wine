default: build 

run:
	./docker-wine

build: Dockerfile
	./build.sh ubuntu-stable
