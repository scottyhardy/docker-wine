#!/usr/bin/env bash

# This script is used in CI pipelines to create checkpoints for building Wine
# from source code. This is used to circumvent the 6 hr job timeout in Github
# workflows

checkpoint_build () {
    if [ ! -f "${MAKE_FLAG}" ]; then
        make
        touch "${MAKE_FLAG}"
    fi

    if [ ! -f "${INSTALL_FLAG}" ]; then
        [ ! -d "${INSTALL_DIR}" ] && mkdir -p "${INSTALL_DIR}"
        make install DESTDIR="${INSTALL_DIR}"
        touch "${INSTALL_FLAG}"
    fi

    if [ ! -f "${OUTPUT_FLAG}" ]; then

        # Confirm there's data in the install dir
        if [ "$(ls -A "${INSTALL_DIR}")" ]; then
            [ ! -d "${OUTPUT_DIR}" ] && mkdir -p "${OUTPUT_DIR}"
            tar -C "${INSTALL_DIR}" -cvzf "${OUTPUT_DIR}/wine.tar.gz" .
        else
            echo "Error with build, ${INSTALL_DIR} is Empty!"
            exit 1
        fi

    fi
}


export TIMEOUT=${TIMEOUT:-5h}
export MAKE_FLAG=/make_done
export INSTALL_FLAG=/install_done
export OUTPUT_FLAG=/output_done
export INSTALL_DIR=/wine-dirs/wine-install
export OUTPUT_DIR=/output
export -f checkpoint_build

if [ ! -f "${MAKE_FLAG}" ] || [ ! -f "${INSTALL_FLAG}" ] || [ ! -f "${OUTPUT_FLAG}" ]; then

    timeout "${TIMEOUT}" bash -c checkpoint_build
    e=$?

    if [ $e -eq 0 ]; then
        echo "Build completed successfully"
        exit 0
    elif [ $e -eq 124 ]; then
        echo "Build exceeded ${TIMEOUT}. Checkpoint created"
        exit 0
    else
        echo "Error with build, exit code ${e}"
        exit $e
    fi

else
    echo "Nothing to do, build already done"
fi
