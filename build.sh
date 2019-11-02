#!/bin/bash

if [ $# -lt 1 ]; then
	echo "ERROR: Please specify a build target"
	echo "e.g."
	echo "	$0 ubuntu-stable"
	exit 1
fi

BUILD_TARGET="$1"
VERSION=$(cat ./VERSION)

BUILDER="docker build"
if ! ${BUILDER%% *} -v >/dev/null 2>&1; then
    BUILDER="buildah bud"
    if ! ${BUILDER%% *} -v >/dev/null 2>&1; then
        echo "Didn't find docker or buildah."
        exit 1
    else
        echo "Didn't find docker, did find buildah, using buildah."
    fi
fi

source ./build_args/${BUILD_TARGET}

$BUILDER \
    --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
    --build-arg GECKO_VER=$GECKO_VER \
    --build-arg GIT_REV=$(git rev-parse HEAD) \
    --build-arg IMAGE_VER=$VERSION \
    --build-arg MONO_VER=$MONO_VER \
    --build-arg WINE_VER=$WINE_VER \
	--build-arg WINEBRANCH=$WINEBRANCH \
    -t docker-wine:${WINEBRANCH}-${VERSION}-local \
	-t docker-wine .
