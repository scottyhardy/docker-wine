#!/usr/bin/env bash

# Scrapes the WineHQ download pages for latest versions of mono and gecko to download

get_hrefs () {
    local url="$1"
    local regexp="$2"

    wget -q -O- "${url}" | sed -E "s/></>\n</g" | sed -n -E "s|^.*<a href=\"(${regexp})\">.*|\1|p" | uniq
}

for APP in "gecko" "mono"; do

    URL="http://dl.winehq.org/wine/wine-${APP}/"

    # Get the latest version
    VER=$(get_hrefs "${URL}" "[0-9]+(\.[0-9]+)*/" | sed -E "s|/$||" | sort -rV | head -1)

    # Get the list of files to download
    mapfile -t FILES < <(get_hrefs "${URL}${VER}/" ".*\.msi")

    # Download the files
    [ ! -d "/usr/share/wine/${APP}" ] && mkdir -p "/usr/share/wine/${APP}"
    for FILE in "${FILES[@]}"; do
        echo "Downloading '${FILE}'"
        wget -nv "${URL}${VER}/${FILE}" -O "/usr/share/wine/${APP}/${FILE}"
    done
done
