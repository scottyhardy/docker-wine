#!/usr/bin/env bash

# Set user account and run values
USER_NAME=${USER_NAME:-wineuser}
USER_UID=${USER_UID:-1010}
USER_GID=${USER_GID:-"${USER_UID}"}
USER_HOME=${USER_HOME:-/home/"${USER_NAME}"}
USER_PASSWD=${USER_PASSWD:-"$(openssl passwd -1 -salt "$(openssl rand -base64 6)" "${USER_NAME}")"}
RDP_SERVER=${RDP_SERVER:-no}
RUN_AS_ROOT=${RUN_AS_ROOT:-no}
FORCED_OWNERSHIP=${FORCED_OWNERSHIP:-no}
TZ=${TZ:-UTC}

# Create the user account
! grep -q ":${USER_GID}:$" /etc/group && groupadd --gid "${USER_GID}" "${USER_NAME}"
useradd --shell /bin/bash --uid "${USER_UID}" --gid "${USER_GID}" --password "${USER_PASSWD}" --no-create-home --home-dir "${USER_HOME}" "${USER_NAME}"

# Create the user's home if it doesn't exist
[ ! -d "${USER_HOME}" ] && mkdir -p "${USER_HOME}"

# Take ownership of user's home directory if owned by root or if FORCED_OWNERSHIP is enabled
OWNER_IDS="$(stat -c "%u:%g" "${USER_HOME}")"
if [ "${OWNER_IDS}" != "${USER_UID}:${USER_GID}" ]; then
    if [ "${OWNER_IDS}" == "0:0" ] || [ "${FORCED_OWNERSHIP}" == "yes" ]; then
        chown -R "${USER_UID}":"${USER_GID}" "${USER_HOME}"
    else
        echo "ERROR: User's home '${USER_HOME}' is currently owned by $(stat -c "%U:%G" "${USER_HOME}")"
        echo "Use option --force-owner to enable user ${USER_NAME} to take ownership"
        exit 1
    fi
fi

# Configure timezone
ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone

# Run in X11 redirection mode (default) or with xvfb
if echo "${RDP_SERVER}" | grep -q -i -E "^(no|off|false|0)$"; then

    # Set up pulseaudio for redirection to UNIX socket
    [ -f /root/pulse/client.conf ] && cp /root/pulse/client.conf /etc/pulse/client.conf

    # Run xvfb
    if echo "${XVFB}" | grep -q -i -E "^(yes|on|true|1)$"; then
        nohup /usr/bin/Xvfb "${XVFB_SERVER}" -screen "${XVFB_SCREEN}" "${XVFB_RESOLUTION}" >/dev/null 2>&1 &
    fi

    # Run in X11 redirection mode as $USER_NAME (default)
    if echo "${RUN_AS_ROOT}" | grep -q -i -E "^(no|off|false|0)$"; then

        # Copy and take ownership of .Xauthority for X11 redirection
        if [ -f /root/.Xauthority ] && [ "${XVFB}" == "no" ]; then
            cp /root/.Xauthority "${USER_HOME}"
            chown "${USER_UID}":"${USER_GID}" "${USER_HOME}/.Xauthority"
        fi

        # Run in X11 redirection mode as user
        exec gosu "${USER_NAME}" "$@"

    # Run in X11 redirection mode as root
    elif echo "${RUN_AS_ROOT}" | grep -q -i -E "^(yes|on|true|1)$"; then
        exec "$@"
    else
        echo "ERROR: '${RUN_AS_ROOT}' is not a valid value for RUN_AS_ROOT"
        exit 1
    fi

# Run in RDP server mode
elif echo "${RDP_SERVER}" | grep -q -i -E "^(yes|on|true|1)$"; then

    # Start xrdp sesman service
    /usr/sbin/xrdp-sesman

    # Run xrdp in foreground if no commands specified
    if [ -z "$1" ]; then
        /usr/sbin/xrdp --nodaemon
    else
        /usr/sbin/xrdp

        if echo "${RUN_AS_ROOT}" | grep -q -i -E "^(no|off|false|0)$"; then
            exec gosu "${USER_NAME}" "$@"
        elif echo "${RUN_AS_ROOT}" | grep -q -i -E "^(yes|on|true|1)$"; then
            exec "$@"
        else
            echo "ERROR: '${RUN_AS_ROOT}' is not a valid value for RUN_AS_ROOT"
            exit 1
        fi
    fi
else
    echo "ERROR: '${RDP_SERVER}' is not a valid value for RDP_SERVER"
fi
