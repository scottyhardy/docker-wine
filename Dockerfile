ARG BASE_IMAGE="scottyhardy/docker-remote-desktop"
ARG TAG="latest"
ARG WINE_BRANCH="stable"
ARG WINE_VERSION="8.0.2"

FROM ${BASE_IMAGE}:${TAG} AS common

# hadolint ignore=DL3008
RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        cabextract \
        git \
        gnupg \
        gosu \
        gpg-agent \
        locales \
        p7zip \
        pulseaudio \
        pulseaudio-utils \
        sudo \
        tzdata \
        unzip \
        wget \
        winbind \
        xauth \
        xvfb \
        zenity && \
    rm -rf /var/lib/apt/lists/*

# Set locale
ENV LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    LC_ALL="en_US.UTF-8"
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8

# Install wine for x86_64
FROM common AS wine-amd64
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG WINE_BRANCH
ARG WINE_VERSION
# hadolint ignore=DL3008
RUN wget -nv -O- https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor -o /usr/share/keyrings/winehq-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/winehq-archive-keyring.gpg] https://dl.winehq.org/wine-builds/debian/ $(grep VERSION_CODENAME= /etc/os-release | cut -d= -f2) main" >> /etc/apt/sources.list.d/winehq.list && \
    dpkg --add-architecture i386 && \
    apt-get update && \
    if [ "${WINE_VERSION}" = "latest" ]; then \
        DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends "winehq-${WINE_BRANCH}"; \
    else \
        echo "Package: winehq-${WINE_BRANCH}" > /etc/apt/preferences.d/winehq && \
        echo "Pin: version ${WINE_VERSION}~$(grep VERSION_CODENAME= /etc/os-release | cut -d= -f2)*" >> /etc/apt/preferences.d/winehq && \
        echo "Pin-Priority: 1001" >> /etc/apt/preferences.d/winehq && \
        echo "Package: wine-${WINE_BRANCH}" >> /etc/apt/preferences.d/winehq && \
        echo "Pin: version ${WINE_VERSION}~$(grep VERSION_CODENAME= /etc/os-release | cut -d= -f2)*" >> /etc/apt/preferences.d/winehq && \
        echo "Pin-Priority: 1001" >> /etc/apt/preferences.d/winehq && \
        DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
            "winehq-${WINE_BRANCH}=${WINE_VERSION}~$(grep VERSION_CODENAME= /etc/os-release | cut -d= -f2)*" \
            "wine-${WINE_BRANCH}=${WINE_VERSION}~$(grep VERSION_CODENAME= /etc/os-release | cut -d= -f2)*" \
            "wine-${WINE_BRANCH}-amd64=${WINE_VERSION}~$(grep VERSION_CODENAME= /etc/os-release | cut -d= -f2)*" \
            "wine-${WINE_BRANCH}-i386=${WINE_VERSION}~$(grep VERSION_CODENAME= /etc/os-release | cut -d= -f2)*"; \
    fi && \
    rm -rf /var/lib/apt/lists/*

# Build box86 and box64 for arm
FROM debian:bookworm-slim AS builder

# hadolint ignore=DL3008
RUN dpkg --add-architecture armhf && \
    apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        cmake \
        gcc-arm-linux-gnueabihf \
        git \
        libc6:armhf \
        libc6-dev-armhf-cross \
        libstdc++6:armhf \
        python3

# Clone and build box86
RUN git clone https://github.com/ptitSeb/box86.git /tmp/box86
WORKDIR /tmp/box86/build
RUN cmake .. -DRPI4ARM64=1 -DARM_DYNAREC=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo && \
    make -j"$(nproc)" && \
    make install DESTDIR=/tmp/install

# Clone and build box64
RUN git clone https://github.com/ptitSeb/box64.git /tmp/box64
WORKDIR /tmp/box64/build
RUN cmake .. -DRPI4ARM64=1 -DARM_DYNAREC=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo && \
    make -j"$(nproc)" && \
    make install DESTDIR=/tmp/install

# Install wine for arm
FROM common AS wine-arm64
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Download x86 wine binaries and install necessary dependencies
ARG WINE_BRANCH
ARG WINE_VERSION
# hadolint ignore=DL3008,SC2046
RUN branch="${WINE_BRANCH}" && \
    id="$(grep ^ID= /etc/os-release | cut -d= -f2)" && \
    dist="$(grep VERSION_CODENAME= /etc/os-release | cut -d= -f2)" && \
    tag="-1" && \
    url_amd64="https://dl.winehq.org/wine-builds/${id}/dists/${dist}/main/binary-amd64/" && \
    url_i386="https://dl.winehq.org/wine-builds/${id}/dists/${dist}/main/binary-i386/" && \
    if [ "${WINE_VERSION}" = "latest" ]; then \
        version="$(wget -qO- ${url_amd64} | grep -oP "wine-${branch}-amd64_\K[0-9.]+(?=~${dist}${tag}_amd64.deb)" | sort -V | tail -n 1)"; \
    else \
        version="${WINE_VERSION}"; \
    fi && \
    echo "Downloading wine version ${version} . . ." && \
    wget -nv "${url_amd64}wine-${branch}-amd64_${version}~${dist}${tag}_amd64.deb" && \
    wget -nv "${url_amd64}wine-${branch}_${version}~${dist}${tag}_amd64.deb" && \
    wget -nv "${url_i386}wine-${branch}-i386_${version}~${dist}${tag}_i386.deb" && \
    wget -nv "${url_i386}wine-${branch}_${version}~${dist}${tag}_i386.deb" && \
    echo "Installing wine . . ." && \
    dpkg-deb -xv "wine-${branch}-amd64_${version}~${dist}${tag}_amd64.deb" / && \
    dpkg-deb -xv "wine-${branch}_${version}~${dist}${tag}_amd64.deb" / && \
    dpkg-deb -xv "wine-${branch}-i386_${version}~${dist}${tag}_i386.deb" / && \
    dpkg-deb -xv "wine-${branch}_${version}~${dist}${tag}_i386.deb" / && \
    echo "Installing dependencies . . ." && \
    dpkg --add-architecture armhf && \
    apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
        $(dpkg-deb -I "wine-${branch}-i386_${version}~${dist}${tag}_i386.deb" | grep -oP 'Depends: \K.*' | tr ',' '\n' | sed -E 's/\(.*\)//g' | sed 's/|.*//' | sed 's/^\s*//;s/\s*$//' | grep -v '^$' | grep -v '^dpkg$' | sed 's/$/:armhf/') \
        $(dpkg-deb -I "wine-${branch}-amd64_${version}~${dist}${tag}_amd64.deb" | grep -oP 'Depends: \K.*' | tr ',' '\n' | sed -E 's/\(.*\)//g' | sed 's/|.*//' | sed 's/^\s*//;s/\s*$//' | grep -v '^$' | grep -v '^dpkg$' | sed 's/$/:arm64/') && \
    rm -f "wine-${branch}-amd64_${version}~${dist}${tag}_amd64.deb" \
          "wine-${branch}_${version}~${dist}${tag}_amd64.deb" \
          "wine-${branch}-i386_${version}~${dist}${tag}_i386.deb" \
          "wine-${branch}_${version}~${dist}${tag}_i386.deb" && \
    rm -rf /var/lib/apt/lists/* && \
    echo "Replacing /bin/bash with box64-bash wrapper . . ." && \
    mv /bin/bash /bin/bash-original && \
    echo "#!/bin/bash-original" > /bin/bash && \
    echo "export BOX64_PATH=/usr/lib/box64-x86_64-linux-gnu" >> /bin/bash && \
    echo "export BOX64_LD_LIBRARY_PATH=/usr/lib/box64-x86_64-linux-gnu" >> /bin/bash && \
    echo "export BOX64_BIN=/usr/local/bin/box64" >> /bin/bash && \
    echo "export BOX64_LOG=\${BOX64_LOG:-0}" >> /bin/bash && \
    echo "export BOX64_NOBANNER=1" >> /bin/bash && \
    echo "export BOX86_PATH=/usr/lib/box86-i386-linux-gnu" >> /bin/bash && \
    echo "export BOX86_LD_LIBRARY_PATH=/usr/lib/box86-i386-linux-gnu" >> /bin/bash && \
    echo "export BOX86_BIN=/usr/local/bin/box86" >> /bin/bash && \
    echo "export BOX86_LOG=\${BOX86_LOG:-0}" >> /bin/bash && \
    echo "export BOX86_NOBANNER=1" >> /bin/bash && \
    echo "export LD_LIBRARY_PATH=/usr/lib/box64-x86_64-linux-gnu:/usr/lib/box86-i386-linux-gnu:\$LD_LIBRARY_PATH" >> /bin/bash && \
    echo "exec /usr/local/bin/box64 /usr/local/bin/box64-bash \"\$@\"" >> /bin/bash && \
    chmod +x /bin/bash

# Copy box86 and box64 install files from builder
COPY --from=builder /tmp/install/ /

# hadolint ignore=DL3006
FROM wine-${TARGETARCH} AS final
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG WINE_BRANCH
RUN echo "Creating wrappers for wine binaries . . ." && \
    for bin in wine wine64 wineboot winecfg wineserver; do \
        rm -f "/usr/bin/${bin}" && \
        echo "#!/bin/bash" > "/usr/bin/${bin}" && \
        echo "export WINEARCH=\${WINEARCH:-win32}" >> "/usr/bin/${bin}" && \
        echo "export WINEDEBUG=\${WINEDEBUG:--all}" >> "/usr/bin/${bin}" && \
        echo "exec /bin/bash -c \"/opt/wine-${WINE_BRANCH}/bin/wine \\\"\\\$@\\\"\" -- \"\$@\"" >> "/usr/bin/${bin}" && \
        chmod +x "/usr/bin/${bin}"; \
    done && \
    echo "Installing winetricks . . ." && \
    wget -nv -O /usr/local/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
    chmod +x /usr/local/bin/winetricks && \
    echo "Downloading mono install files . . ." && \
    wine_version="$(wine --version | sed -E 's/^wine-//')" && \
    mono_version="$(wget -q -O- "https://raw.githubusercontent.com/wine-mirror/wine/wine-${wine_version}/dlls/appwiz.cpl/addons.c" | grep -E "^#define MONO_VERSION\s" | awk -F\" '{print $2}')" && \
    mono_url="http://dl.winehq.org/wine/wine-mono/${mono_version}/" && \
    mapfile -t files < <(wget -q -O- "${mono_url}" | sed -E "s/></>\n</g" | sed -n -E "s|^.*<a href=\"(.*\.msi)\">.*|\1|p" | uniq) && \
    mkdir -p "/usr/share/wine/mono" && \
    for file in "${files[@]}"; do \
        echo "Downloading ${file} . . ." && \
        wget -nv -O "/usr/share/wine/mono/${file}" "${mono_url}${file}"; \
    done

# Copy configuration files
COPY pulse-client.conf /root/pulse/client.conf
COPY entrypoint.sh /usr/bin/entrypoint

ENTRYPOINT ["/usr/bin/entrypoint"]
