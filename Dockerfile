FROM ubuntu:bionic
RUN export DEBIAN_FRONTEND="noninteractive" \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        cabextract \
        gosu \
        gpg-agent \
        p7zip \
        pulseaudio-utils \
        software-properties-common \
        unzip \
        wget \
        winbind \
        zenity \
    && rm -rf /var/lib/apt/lists/*
ARG WINEBRANCH
ARG WINE_VER
RUN wget https://dl.winehq.org/wine-builds/winehq.key \
    && apt-key add winehq.key \
    && apt-add-repository "deb https://dl.winehq.org/wine-builds/ubuntu/ bionic main" \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --install-recommends winehq-${WINEBRANCH}="${WINE_VER}" \
    && rm -rf /var/lib/apt/lists/* \
    && rm winehq.key
# Download mono and gecko
ARG MONO_VER
ARG GECKO_VER
RUN mkdir -p /usr/share/wine/mono /usr/share/wine/gecko \
    && wget https://dl.winehq.org/wine/wine-mono/${MONO_VER}/wine-mono-${MONO_VER}.msi \
        -O /usr/share/wine/mono/wine-mono-${MONO_VER}.msi \
    && wget https://dl.winehq.org/wine/wine-gecko/${GECKO_VER}/wine_gecko-${GECKO_VER}-x86.msi \
        -O /usr/share/wine/gecko/wine_gecko-${GECKO_VER}-x86.msi \
    && wget https://dl.winehq.org/wine/wine-gecko/${GECKO_VER}/wine_gecko-${GECKO_VER}-x86_64.msi \
        -O /usr/share/wine/gecko/wine_gecko-${GECKO_VER}-x86_64.msi
# Download winetricks
RUN wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
        -O /usr/bin/winetricks \
    && chmod +rx /usr/bin/winetricks
# Create user and take ownership of files
RUN groupadd -g 1010 wineuser \
    && useradd --shell /bin/bash --uid 1010 --gid 1010 --create-home --home-dir /home/wineuser wineuser \
    && chown -R wineuser:wineuser /home/wineuser
VOLUME /home/wineuser
COPY pulse-client.conf /etc/pulse/client.conf
COPY entrypoint.sh /usr/bin/entrypoint
WORKDIR /home/wineuser
ARG IMAGE_VER
ARG BUILD_DATE
ARG GIT_REV
LABEL \
    org.opencontainers.image.authors="scottyhardy <scotthardy42@outlook.com>" \
    org.opencontainers.image.created="${BUILD_DATE}" \
    org.opencontainers.image.description="Docker image that includes Wine and Winetricks for running Windows applications on Linux and macOS" \
    org.opencontainers.image.documentation="https://github.com/scottyhardy/docker-wine/blob/${IMAGE_VER}/README.md" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.revision="${GIT_REV}" \
    org.opencontainers.image.source="https://github.com/scottyhardy/docker-wine.git" \
    org.opencontainers.image.title="docker-wine" \
    org.opencontainers.image.url="https://github.com/scottyhardy/docker-wine" \
    org.opencontainers.image.vendor="scottyhardy" \
    org.opencontainers.image.version="${IMAGE_VER}"
ENTRYPOINT ["/usr/bin/entrypoint"]
CMD ["/bin/bash"]
