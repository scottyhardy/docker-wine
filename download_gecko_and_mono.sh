#!/usr/bin/env bash

# Scrapes the Wine source code for versions of mono and gecko to download for a given version of Wine

get_hrefs () {
    local url="$1"
    local regexp="$2"

    wget -q -O- "${url}" | sed -E "s/></>\n</g" | sed -n -E "s|^.*<a href=\"(${regexp})\">.*|\1|p" | uniq
}

get_app_ver () {
    local app="${1^^}"  # Convert to uppercase
    local url="https://raw.githubusercontent.com/wine-mirror/wine/wine-${WINE_VER}/dlls/appwiz.cpl/addons.c"

    wget -q -O- "${url}" | grep -E "^#define ${app}_VERSION\s" | awk -F\" '{print $2}'
}


WINE_VER="$1"

if [ -z "${WINE_VER}" ]; then
    echo "Please specify the version of wine that requires gecko and mono installers"
    echo "e.g."
    echo "  $0 5.0.1"
    exit 1
fi

for APP in "gecko" "mono"; do

    # Get the app version required from wine source code
    APP_VER=$(get_app_ver "${APP}")

    # Get the list of files to download
    APP_URL="http://dl.winehq.org/wine/wine-${APP}/${APP_VER}/"
    mapfile -t FILES < <(get_hrefs "${APP_URL}" ".*\.msi")

    # Download the files
    [ ! -d "/usr/share/wine/${APP}" ] && mkdir -p "/usr/share/wine/${APP}"
    for FILE in "${FILES[@]}"; do
        echo "Downloading '${FILE}'"
        wget -nv -O "/usr/share/wine/${APP}/${FILE}" "${APP_URL}${FILE}"
    done
done
