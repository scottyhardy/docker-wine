FROM ubuntu:16.04 as wine-base

ARG IMAGE_VER="0.6.0"
ARG BUILD_DATE
ARG GIT_REV
LABEL org.opencontainers.image.authors="scottyhardy <scotthardy42@outlook.com>"
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.description="This container runs wine on your Linux desktop and uses your local X11 server for graphics"
LABEL org.opencontainers.image.documentation="https://github.com/scottyhardy/docker-wine/blob/${IMAGE_VER}/README.md"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.title="docker-wine"
LABEL org.opencontainers.image.revision="${GIT_REV}"
LABEL org.opencontainers.image.source="https://github.com/scottyhardy/docker-wine.git"
LABEL org.opencontainers.image.url="https://github.com/scottyhardy/docker-wine"
LABEL org.opencontainers.image.vendor="scottyhardy"
LABEL org.opencontainers.image.version="${IMAGE_VER}"

# Prevents annoying debconf errors during builds
RUN export DEBIAN_FRONTEND="noninteractive" \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        apt-transport-https \
        cabextract \
        gosu \
        p7zip \
        software-properties-common \
        unzip \
        wget \
        winbind \
        zenity \
    # Install wine
    && wget -nc https://dl.winehq.org/wine-builds/winehq.key \
    && apt-key add winehq.key \
    && apt-add-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ xenial main' \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --install-recommends winehq-stable \
    # Clean up
    && apt-get autoremove -y \
        software-properties-common \
    && rm -rf /var/lib/apt/lists/* \
    && rm winehq.key


FROM wine-base as wine-cache
ARG MONO_VER="4.7.5"
ARG GECKO_VER="2.47"
RUN mkdir -p /usr/share/wine/mono /usr/share/wine/gecko \
    # Download wine cache files
    && wget https://dl.winehq.org/wine/wine-mono/${MONO_VER}/wine-mono-${MONO_VER}.msi \
        -O /usr/share/wine/mono/wine-mono-${MONO_VER}.msi \
    && wget https://dl.winehq.org/wine/wine-gecko/${GECKO_VER}/wine_gecko-${GECKO_VER}-x86.msi \
        -O /usr/share/wine/gecko/wine_gecko-${GECKO_VER}-x86.msi \
    && wget https://dl.winehq.org/wine/wine-gecko/${GECKO_VER}/wine_gecko-${GECKO_VER}-x86_64.msi \
        -O /usr/share/wine/gecko/wine_gecko-${GECKO_VER}-x86_64.msi \
    # Download winetricks and cache files
    && wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
        -O /usr/bin/winetricks \
    && chmod +rx /usr/bin/winetricks \
    && mkdir -p /home/wine/.cache/winetricks/win7sp1 \
    && wget https://download.microsoft.com/download/0/A/F/0AFB5316-3062-494A-AB78-7FB0D4461357/windows6.1-KB976932-X86.exe \
        -O /home/wine/.cache/winetricks/win7sp1/windows6.1-KB976932-X86.exe


FROM wine-cache as wine-user
# Create user and take ownership of files
RUN groupadd -g 1010 wine \
    && useradd -s /bin/bash -u 1010 -g 1010 wine \
    && chown -R wine:wine /home/wine
VOLUME /home/wine


FROM wine-user as wine-final
COPY entrypoint.sh /usr/bin/entrypoint
ENTRYPOINT ["/usr/bin/entrypoint"]
CMD ["/bin/bash"]
