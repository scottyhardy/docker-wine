#!/usr/bin/env bash

# This script is used in CI pipelines to create checkpoints for building Wine
# from source code. This is used to circumvent the 6 hr job timeout in Github
# workflows

build () {
        make -j "$(nproc)"
        make install DESTDIR=/wine-dirs/wine-install
}


export TIMEOUT=${TIMEOUT:-5h}
export BUILD_FLAG=/build_done
export -f build

if [ ! -f "${BUILD_FLAG}" ]; then

    timeout "${TIMEOUT}" bash -c build
    e=$?

    if [ $e -eq 0 ]; then
        touch "${BUILD_FLAG}"
        echo "Build completed successfully"
        exit 0
    elif [ $e -eq 124 ]; then
        echo "Build timed out, exceeded ${TIMEOUT}"
        exit 0
    else
        echo "Build exited with error, exit code ${e}"
        exit $e
    fi

else
    echo "Nothing to do, build already done"
fi
