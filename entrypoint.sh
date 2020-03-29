#!/bin/bash

# Set user account details
USER="${USER:-wineuser}"
USER_UID="${USER_UID:-1010}"
USER_GID="${USER_GID:-1010}"
USER_HOME="${USER_HOME:-/home/wineuser}"
USER_PASSWD="${USER_PASSWORD:-ubuntu}"

# Create the user account
groupadd --gid "${USER_GID}" "${USER}"
useradd --shell /bin/bash --uid 1010 --gid 1010 --password $(openssl passwd "${USER_PASSWORD}") --no-create-home --home-dir "${USER_HOME}" "${USER}"

# Create the user's home if it doesn't exist
[ ! -d "${USER_HOME}" ] && mkdir -p "${USER_HOME}"

# Take ownership of user's home directory
if [ "$(stat -c '%u:%g' ${USER_HOME})" != "${USER_UID}:${USER_GID}" ]; then
    chown "${USER_UID}":"${USER_GID}" "${USER_HOME}"
fi

# Container can be run with X11 redirection or as an RDP server
RDP_SERVER="${RDP_SERVER:-no}"

# Can run as root for troubleshooting, default is to run as $USER
RUN_AS_ROOT="${RUN_AS_ROOT:-no}"

# Run in X11 redirection mode (default)
if echo "${RDP_SERVER}" | grep -q -i -E '^(no|off|false|0)$'; then

    # Run in X11 redirection mode as $USER (default)
    if echo "${RUN_AS_ROOT}" | grep -q -i -E '^(no|off|false|0)$'; then

        # Copy and take ownership of .Xauthority for X11 redirection
        if [ -f /root/.Xauthority ]; then
            cp /root/.Xauthority "${USER_HOME}"
            chown "${USER_UID}":"${USER_GID}" "${USER_HOME}/.Xauthority"
        fi

        exec gosu "${USER}" "$@"

    # Run in X11 redirection mode as root
    elif echo "${RUN_AS_ROOT}" | grep -q -i -E '^(yes|on|true|1)$'; then
        exec "$@"
    else
        echo "ERROR: '${RUN_AS_ROOT}' is not a valid value for RUN_AS_ROOT"
        exit 1
    fi

# Run as RDP server
elif echo "${RDP_SERVER}" | grep -q -i -E '^(yes|on|true|1)$'; then

    # Start xrdp sesman service
    /usr/sbin/xrdp-sesman

    # Run xrdp in foreground if no commands specified
    if [ -z "$1" ]; then
        /usr/sbin/xrdp --nodaemon
    else
        /usr/sbin/xrdp

        if echo "${RUN_AS_ROOT}" | grep -q -i -E '^(no|off|false|0)$'; then
            exec gosu "${USER}" "$@"
        elif echo "${RUN_AS_ROOT}" | grep -q -i -E '^(yes|on|true|1)$'; then
            exec "$@"
        else
            echo "ERROR: '${RUN_AS_ROOT}' is not a valid value for RUN_AS_ROOT"
            exit 1
        fi
    fi
else
    echo "ERROR: '${RDP_SERVER} is not a valid value for RDP_SERVER'"
fi
