#!/bin/bash

USER="${USER:-wineuser}"
USER_UID="${USER_UID:-1010}"
USER_GID="${USER_GID:-1010}"
USER_HOME="${USER_HOME:-/home/wineuser}"

# Create the user account
groupadd --gid "${USER_GID}" "${USER}"
useradd --shell /bin/bash --uid 1010 --gid 1010 --no-create-home --home-dir /home/wineuser wineuser

# Create the user's home if it doesn't exist
if [ ! -d "${USER_HOME}" ]; then
    mkdir -p "${USER_HOME}"
fi

# Take ownership of user's home directory
if [ "$(stat -c '%u:%g' ${USER_HOME})" != "${USER_UID}:${USER_GID}" ]; then
    chown "${USER_UID}":"${USER_GID}" "${USER_HOME}"
fi

# Copy and take ownership of .Xauthority
if [ -f /root/.Xauthority ]; then
    cp /root/.Xauthority "${USER_HOME}"
    chown "${USER_UID}":"${USER_GID}" "${USER_HOME}/.Xauthority"
fi

exec gosu wineuser "$@"
