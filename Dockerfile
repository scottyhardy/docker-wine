ARG BASE_IMAGE="scottyhardy/docker-remote-desktop"
ARG TAG="latest"

FROM ${BASE_IMAGE}:${TAG} AS builder

# Install dependencies for building Box86 and Box64
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
RUN git clone https://github.com/ptitSeb/box86.git /tmp/box86 && \
    mkdir /tmp/box86/build && \
    cd /tmp/box86/build && \
    cmake .. -DRPI4ARM64=1 -DARM_DYNAREC=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo && \
    make -j$(nproc) && \
    make install DESTDIR=/tmp/install

# Clone and build Box64
RUN git clone https://github.com/ptitSeb/box64.git /tmp/box64 && \
    mkdir /tmp/box64/build && \
    cd /tmp/box64/build && \
    cmake .. -DRPI4ARM64=1 -DARM_DYNAREC=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo && \
    make -j$(nproc) && \
    make install DESTDIR=/tmp/install

FROM ${BASE_IMAGE}:${TAG}

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

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install Wine for x86_64
ARG WINE_BRANCH="stable"
# hadolint ignore=DL3008
RUN if [ "$(uname -m)" = "x86_64" ]; then \
        wget -nv -O- https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor -o /usr/share/keyrings/winehq-archive-keyring.gpg && \
        echo "deb [signed-by=/usr/share/keyrings/winehq-archive-keyring.gpg] https://dl.winehq.org/wine-builds/ubuntu/ $(grep VERSION_CODENAME= /etc/os-release | cut -d= -f2) main" >> /etc/apt/sources.list.d/winehq.list && \
        dpkg --add-architecture i386 && \
        apt-get update && \
        apt-get install -y --no-install-recommends "winehq-${WINE_BRANCH}" && \
        rm -rf /var/lib/apt/lists/*; \
    fi

# Download and extract x86_64 Wine binaries for ARM build
ARG ARM_WINE_VERSION="8.0.2"
ARG ARM_WINE_DIST
RUN if [ "$(uname -m)" = "aarch64" ]; then \
        branch="${WINE_BRANCH}" && \
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
        ln -s "/opt/wine-${branch}/bin/wineserver" /usr/bin/wineserver; \
    fi

# Download Wine dependencies
RUN if [ "$(uname -m)" = "aarch64" ]; then \
        branch="${WINE_BRANCH}" && \
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
        rm -rf /var/lib/apt/lists/*; \
    fi

# Install Winetricks
RUN wget -nv -O /usr/local/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
    chmod +x /usr/local/bin/winetricks

# Copy Box86 and Box64 binaries and libraries from builder
COPY --from=builder /tmp/install/ /

# Configure locale for unicode
ENV LANG=en_US.UTF-8
RUN locale-gen en_US.UTF-8

# Replace /bin/bash with box64-bash wrapper
RUN mv /bin/bash /bin/bash-native && \
    printf "#!/bin/bash-native\nexport BOX64_PATH=/usr/lib/box64-x86_64-linux-gnu\nexport BOX64_LD_LIBRARY_PATH=/usr/lib/box64-x86_64-linux-gnu\nexport BOX64_BIN=/usr/local/bin/box64\nexport BOX64_LOG=0\nexport BOX64_NOBANNER=1\nexport BOX86_PATH=/usr/lib/box86-i386-linux-gnu\nexport BOX86_LD_LIBRARY_PATH=/usr/lib/box86-i386-linux-gnu\nexport BOX86_BIN=/usr/local/bin/box86\nexport BOX86_LOG=0\nexport BOX86_NOBANNER=1\nexport LD_LIBRARY_PATH=/usr/lib/box64-x86_64-linux-gnu:/usr/lib/box86-i386-linux-gnu:\$LD_LIBRARY_PATH\nexec /usr/local/bin/box64 /usr/local/bin/box64-bash \"\$@\"" > /bin/bash && \
    chmod +x /bin/bash

# Replace wine symlinks with wrappers
RUN for bin in wine wine64 wineboot winecfg wineserver; do \
        rm -f "/usr/bin/${bin}" && \
        printf "#!/bin/bash-native\nexport BOX64_PATH=/usr/lib/box64-x86_64-linux-gnu\nexport BOX64_LD_LIBRARY_PATH=/usr/lib/box64-x86_64-linux-gnu\nexport BOX64_BIN=/usr/local/bin/box64\nexport BOX64_LOG=0\nexport BOX64_NOBANNER=1\nexport BOX86_PATH=/usr/lib/box86-i386-linux-gnu\nexport BOX86_LD_LIBRARY_PATH=/usr/lib/box86-i386-linux-gnu\nexport BOX86_BIN=/usr/local/bin/box86\nexport BOX86_LOG=0\nexport BOX86_NOBANNER=1\nexport LD_LIBRARY_PATH=/usr/lib/box64-x86_64-linux-gnu:/usr/lib/box86-i386-linux-gnu:\$LD_LIBRARY_PATH\nexport WINEARCH=\${WINEARCH:-win32}\nexport WINEPREFIX=\${WINEPREFIX:-\$HOME/.wine}\nexec /usr/local/bin/box64 /usr/local/bin/box64-bash -c \"/opt/wine-${WINE_BRANCH}/bin/${bin} \"\$@\"\"" > "/usr/bin/${bin}" && \
        chmod +x "/usr/bin/${bin}"; \
    done

# Download gecko and mono installers
COPY download_gecko_and_mono.sh /root/download_gecko_and_mono.sh
RUN /root/download_gecko_and_mono.sh "$(wine --version | sed -E 's/^wine-//')"

# Copy configuration files
COPY pulse-client.conf /root/pulse/client.conf
COPY entrypoint.sh /usr/bin/entrypoint

ENTRYPOINT ["/usr/bin/entrypoint"]
