#!/bin/bash

if [ $# -lt 1 ]; then
	echo "ERROR: Please specify a build target"
	echo "e.g."
	echo "	$0 ubuntu-stable"
	exit 1
fi

BUILD_TARGET="$1"

source ./build_args/${BUILD_TARGET}

docker build \
    --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
    --build-arg GECKO_VER=$GECKO_VER \
    --build-arg GIT_REV=$(git rev-parse HEAD) \
    --build-arg IMAGE_VER=$(cat ./VERSION) \
    --build-arg MONO_VER=$MONO_VER \
    --build-arg WINE_VER=$WINE_VER \
	--build-arg WINEBRANCH=$WINEBRANCH \
	-t docker-wine .
