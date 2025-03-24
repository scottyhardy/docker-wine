ARG BASE_IMAGE="scottyhardy/docker-remote-desktop"
ARG TAG="latest"
ARG WINE_BRANCH="stable"

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

# Install Wine for x86_64
FROM common AS wine-amd64
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG WINE_BRANCH
# hadolint ignore=DL3008
RUN wget -nv -O- https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor -o /usr/share/keyrings/winehq-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/winehq-archive-keyring.gpg] https://dl.winehq.org/wine-builds/debian/ $(grep VERSION_CODENAME= /etc/os-release | cut -d= -f2) main" >> /etc/apt/sources.list.d/winehq.list && \
    dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends "winehq-${WINE_BRANCH}" && \
    rm -rf /var/lib/apt/lists/*

# Build Box86 and Box64 for ARM
FROM ${BASE_IMAGE}:${TAG} AS builder

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

# Clone and build Box86
RUN git clone https://github.com/ptitSeb/box86.git /tmp/box86
WORKDIR /tmp/box86/build
RUN cmake .. -DRPI4ARM64=1 -DARM_DYNAREC=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo && \
    make -j"$(nproc)" && \
    make install DESTDIR=/tmp/install

# Clone and build Box64
RUN git clone https://github.com/ptitSeb/box64.git /tmp/box64
WORKDIR /tmp/box64/build
RUN cmake .. -DRPI4ARM64=1 -DARM_DYNAREC=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo && \
    make -j"$(nproc)" && \
    make install DESTDIR=/tmp/install

# Install Wine for ARM
FROM common AS wine-arm64
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Download and extract x86_64 Wine binaries for ARM build
ARG WINE_BRANCH
ARG ARM_WINE_DIST
ARG ARM_WINE_VERSION="8.0.2"
RUN branch="${WINE_BRANCH}" && \
    id="$(grep ^ID= /etc/os-release | cut -d= -f2)" && \
    if [ -z "${ARM_WINE_DIST}" ]; then \
        dist="$(grep VERSION_CODENAME= /etc/os-release | cut -d= -f2)"; \
    else \
        dist="${ARM_WINE_DIST}"; \
    fi && \
    tag="-1" && \
    url_amd64="https://dl.winehq.org/wine-builds/${id}/dists/${dist}/main/binary-amd64/" && \
    if [ "${ARM_WINE_VERSION}" = "latest" ]; then \
        version="$(wget -qO- ${url_amd64} | grep -oP "wine-${branch}-amd64_\K[0-9.]+(?=~${dist}${tag}_amd64.deb)" | sort -V | tail -n 1)"; \
    else \
        version="${ARM_WINE_VERSION}"; \
    fi && \
    wget -nv "${url_amd64}wine-${branch}-amd64_${version}~${dist}${tag}_amd64.deb" && \
    wget -nv "${url_amd64}wine-${branch}_${version}~${dist}${tag}_amd64.deb" && \
    url_i386="https://dl.winehq.org/wine-builds/${id}/dists/${dist}/main/binary-i386/" && \
    wget -nv "${url_i386}wine-${branch}-i386_${version}~${dist}${tag}_i386.deb" && \
    echo -e "Extracting wine . . ." && \
    dpkg-deb -xv "wine-${branch}-amd64_${version}~${dist}${tag}_amd64.deb" wine-installer && \
    dpkg-deb -xv "wine-${branch}_${version}~${dist}${tag}_amd64.deb" wine-installer && \
    dpkg-deb -xv "wine-${branch}-i386_${version}~${dist}${tag}_i386.deb" wine-installer && \
    echo -e "Installing wine . . ." && \
    mv "wine-installer/opt/wine-${branch}" /opt/ && \
    rm -rf wine-installer *.deb && \
    ln -s "/opt/wine-${branch}/bin/wine" /usr/bin/wine && \
    ln -s "/opt/wine-${branch}/bin/wine64" /usr/bin/wine64 && \
    ln -s "/opt/wine-${branch}/bin/wineboot" /usr/bin/wineboot && \
    ln -s "/opt/wine-${branch}/bin/winecfg" /usr/bin/winecfg && \
    ln -s "/opt/wine-${branch}/bin/wineserver" /usr/bin/wineserver

# Download Wine dependencies
# hadolint ignore=DL3008
RUN branch="${WINE_BRANCH}" && \
    id="$(grep ^ID= /etc/os-release | cut -d= -f2)" && \
    if [ -z "${ARM_WINE_DIST}" ]; then \
        dist="$(grep VERSION_CODENAME= /etc/os-release | cut -d= -f2)"; \
    else \
        dist="${ARM_WINE_DIST}"; \
    fi && \
    tag="-1" && \
    url_amd64="https://dl.winehq.org/wine-builds/${id}/dists/${dist}/main/binary-amd64/" && \
    if [ "${ARM_WINE_VERSION}" = "latest" ]; then \
        version="$(wget -qO- ${url_amd64} | grep -oP "wine-${branch}-amd64_\K[0-9.]+(?=~${dist}${tag}_amd64.deb)" | sort -V | tail -n 1)"; \
    else \
        version="${ARM_WINE_VERSION}"; \
    fi && \
    wget -nv "${url_amd64}wine-${branch}-amd64_${version}~${dist}${tag}_amd64.deb" && \
    url_i386="https://dl.winehq.org/wine-builds/${id}/dists/${dist}/main/binary-i386/" && \
    wget -nv "${url_i386}wine-${branch}-i386_${version}~${dist}${tag}_i386.deb" && \
    echo -e "Downloading dependencies . . ." && \
    dpkg --add-architecture armhf && apt-get update && \
    apt-get install -y $(dpkg-deb -I "wine-${branch}-i386_${version}~${dist}${tag}_i386.deb" | grep -oP 'Depends: \K.*' | tr ',' '\n' | sed -E 's/\(.*\)//g' | sed 's/|.*//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' | grep -v '^dpkg$' | sed 's/$/:armhf/') && \
    apt-get install -y $(dpkg-deb -I "wine-${branch}-amd64_${version}~${dist}${tag}_amd64.deb" | grep -oP 'Depends: \K.*' | tr ',' '\n' | sed -E 's/\(.*\)//g' | sed 's/|.*//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' | grep -v '^dpkg$' | sed 's/$/:arm64/') && \
    echo "Installing extra dependencies . . ." && \
    apt-get install -y libc6:armhf libstdc++6:armhf && \
    rm -f "wine-${branch}-i386_${version}~${dist}${tag}_i386.deb" "wine-${branch}-amd64_${version}~${dist}${tag}_amd64.deb" && \
    rm -rf /var/lib/apt/lists/*

# Replace /bin/bash with box64-bash wrapper
RUN mv /bin/bash /bin/bash-original && \
    printf "#!/bin/bash-original\n" > /bin/bash && \
    printf "export BOX64_PATH=/usr/lib/box64-x86_64-linux-gnu\n" >> /bin/bash && \
    printf "export BOX64_LD_LIBRARY_PATH=/usr/lib/box64-x86_64-linux-gnu\n" >> /bin/bash && \
    printf "export BOX64_BIN=/usr/local/bin/box64\n" >> /bin/bash && \
    printf "export BOX64_LOG=0\n" >> /bin/bash && \
    printf "export BOX64_NOBANNER=1\n" >> /bin/bash && \
    printf "export BOX86_PATH=/usr/lib/box86-i386-linux-gnu\n" >> /bin/bash && \
    printf "export BOX86_LD_LIBRARY_PATH=/usr/lib/box86-i386-linux-gnu\n" >> /bin/bash && \
    printf "export BOX86_BIN=/usr/local/bin/box86\n" >> /bin/bash && \
    printf "export BOX86_LOG=0\n" >> /bin/bash && \
    printf "export BOX86_NOBANNER=1\n" >> /bin/bash && \
    printf "export LD_LIBRARY_PATH=/usr/lib/box64-x86_64-linux-gnu:/usr/lib/box86-i386-linux-gnu:\$LD_LIBRARY_PATH\n" >> /bin/bash && \
    printf "exec /usr/local/bin/box64 /usr/local/bin/box64-bash \"\$@\"\n" >> /bin/bash && \
    chmod +x /bin/bash

# Copy Box86 and Box64 binaries and libraries from builder
COPY --from=builder /tmp/install/ /

# Create Wine wrapper scripts
RUN for bin in wine wine64 wineboot winecfg wineserver; do \
        rm -f "/usr/bin/${bin}" && \
        printf "#!/bin/bash\n" > "/usr/bin/${bin}" && \
        printf "export WINEARCH=\${WINEARCH:-win32}\n" >> "/usr/bin/${bin}" && \
        printf "export WINEPREFIX=\${WINEPREFIX:-\$HOME/.wine}\n" >> "/usr/bin/${bin}" && \
        printf "exec /bin/bash -c \"/opt/wine-%s/bin/%s \"\$@\"\"\n" "${WINE_BRANCH}" "${bin}" >> "/usr/bin/${bin}" && \
        chmod +x "/usr/bin/${bin}"; \
    done


# hadolint ignore=DL3006
FROM wine-${TARGETARCH} AS final
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install Winetricks
RUN wget -nv -O /usr/local/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
    chmod +x /usr/local/bin/winetricks

# Set locale
ENV LANG=en_US.UTF-8
RUN locale-gen en_US.UTF-8

# Download gecko and mono installers
COPY download_gecko_and_mono.sh /root/download_gecko_and_mono.sh
RUN /root/download_gecko_and_mono.sh "$(wine --version | sed -E 's/^wine-//')"

# Copy configuration files
COPY pulse-client.conf /root/pulse/client.conf
COPY entrypoint.sh /usr/bin/entrypoint

ENTRYPOINT ["/usr/bin/entrypoint"]
