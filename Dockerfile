ARG BASE_IMAGE="scottyhardy/docker-remote-desktop"
ARG TAG="latest"
FROM ${BASE_IMAGE}:${TAG} AS common

# Install prerequisites
RUN apt-get update \
    && DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
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
        xvfb \
        zenity \
    && rm -rf /var/lib/apt/lists/*

FROM common AS wine-amd64
# Install wine
ARG WINE_BRANCH="stable"
RUN wget -nv -O- https://dl.winehq.org/wine-builds/winehq.key | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 apt-key add - \
    && echo "deb https://dl.winehq.org/wine-builds/ubuntu/ $(grep VERSION_CODENAME= /etc/os-release | cut -d= -f2) main" >> /etc/apt/sources.list \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && DEBIAN_FRONTEND="noninteractive" apt-get install -y --install-recommends winehq-${WINE_BRANCH} \
    && rm -rf /var/lib/apt/lists/*

# Install winetricks
RUN wget -nv -O /usr/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
    && chmod +x /usr/bin/winetricks


FROM ubuntu:noble AS builder-arm64
RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    gcc-arm-linux-gnueabihf \
    git \
    python3 \
    wget

# Clone and build box64
RUN git clone https://github.com/ptitSeb/box64.git /tmp/box64
WORKDIR /tmp/box64/build
RUN cmake .. -DRPI4ARM64=1 -DARM_DYNAREC=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo && \
    make -j"$(nproc)" && \
    make install DESTDIR=/tmp/install

FROM common AS wine-arm64
# Install wine
ARG WINE_BRANCH="stable"
RUN wget -nv -O- https://dl.winehq.org/wine-builds/winehq.key | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 apt-key add - \
    && echo "deb https://dl.winehq.org/wine-builds/ubuntu/ $(grep VERSION_CODENAME= /etc/os-release | cut -d= -f2) main" >> /etc/apt/sources.list \
    && dpkg --add-architecture amd64 \
    && dpkg --add-architecture i386 \
    && sed -i'' 's#\(Components:.*\)#\1\nArchitectures: arm64#g' /etc/apt/sources.list.d/ubuntu.sources \
    && echo deb [arch=amd64,i386] http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse >> /etc/apt/sources.list.d/amd64.list \
    && echo deb [arch=amd64,i386] http://archive.ubuntu.com/ubuntu noble-updates main restricted universe multiverse >> /etc/apt/sources.list.d/amd64.list \
    && echo deb [arch=amd64,i386] http://security.ubuntu.com/ubuntu noble-security main restricted universe multiverse >> /etc/apt/sources.list.d/amd64.list \
    && echo deb [arch=amd64,i386] http://archive.ubuntu.com/ubuntu noble-backports main restricted universe multiverse >> /etc/apt/sources.list.d/amd64.list \
    && apt-get update \
    && DEBIAN_FRONTEND="noninteractive" apt-get install -f -y --install-recommends winehq-${WINE_BRANCH} \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder-arm64 /tmp/install/ /

RUN apt-get update \
    && DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
    libsdl2-2.0 \
    libxss1 \
    libdecor-0.0 \
    && rm -rf /var/lib/apt/lists/*

RUN echo "Creating wrappers for wine binaries . . ." && \
    for bin in $(ls /opt/wine-${WINE_BRANCH}/bin); do \
    rm -f "/usr/bin/${bin}" && \
    echo "#!/bin/bash" > "/usr/bin/${bin}" && \
    echo "export BOX64_PATH=/usr/lib/box64-x86_64-linux-gnu" >> "/usr/bin/${bin}" && \
    echo "export BOX64_LD_LIBRARY_PATH=/usr/lib/box64-x86_64-linux-gnu" >> "/usr/bin/${bin}" && \
    echo "export BOX64_BIN=/usr/local/bin/box64" >> "/usr/bin/${bin}" && \
    echo "export BOX64_LOG=\${BOX64_LOG:-0}" >> "/usr/bin/${bin}" && \
    echo "export BOX64_NOBANNER=1" >> "/usr/bin/${bin}" && \
    echo "export BOX64_BASH=/usr/local/bin/box64-bash" >> "/usr/bin/${bin}" && \
    echo "export LD_LIBRARY_PATH=/usr/lib/box64-x86_64-linux-gnu:\$LD_LIBRARY_PATH" >> "/usr/bin/${bin}" && \
    echo "export WINEARCH=\${WINEARCH:-wow64}" >> "/usr/bin/${bin}" && \
    echo "export WINE_BINDIR=/opt/wine-${WINE_BRANCH}/bin" >> "/usr/bin/${bin}" && \
    echo "exec /bin/bash -c \"/usr/local/bin/box64 /opt/wine-${WINE_BRANCH}/bin/${bin} \\\"\\\$@\\\"\" -- \"\$@\"" >> "/usr/bin/${bin}" && \
    chmod +x "/usr/bin/${bin}"; \
    done

# Install winetricks and set up wine bindir inside it
RUN wget -nv -O /usr/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
    && chmod +x /usr/bin/winetricks \
    && sed -i'' "2iexport WINE_BINDIR=/opt/wine-${WINE_BRANCH}/bin" /usr/bin/winetricks

FROM wine-${TARGETARCH} AS final

# Download gecko and mono installers
COPY download_gecko_and_mono.sh /root/download_gecko_and_mono.sh
RUN chmod +x /root/download_gecko_and_mono.sh \
    && /root/download_gecko_and_mono.sh "$(wine --version | sed -E 's/^wine-//')"

# Configure locale for unicode
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8

COPY pulse-client.conf /root/pulse/client.conf
COPY entrypoint.sh /usr/bin/entrypoint
ENTRYPOINT ["/usr/bin/entrypoint"]
