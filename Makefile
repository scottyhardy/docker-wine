default: build 

branch := $(shell git rev-parse --abbrev-ref HEAD)	
branch := $(shell echo $(branch) | perl -pe 's/\//-/g')
branch := $(shell echo -$(branch))
branch := $(shell echo $(branch) | perl -pe 's/-master//')

run:
	./docker-wine

build: Dockerfile
	docker build -t docker-wine$(branch) . 
