default: build 

run:
	./docker-wine
build: Dockerfile
	docker build -t docker-wine . 
