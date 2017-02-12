FROM ubuntu:16.04
ENV HOME="/home/wine"
ARG DEBIAN_FRONTEND="noninteractive"
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y \
# Required for adding repositories
        software-properties-common \
# Required for wine
        winbind \
# Required for winetricks
        cabextract \
        unzip \
        p7zip \
        wget \
        zenity \
    && add-apt-repository ppa:wine/wine-builds \
    && apt-get update \
    && apt-get install -y --install-recommends winehq-staging \
    && mkdir -p $HOME/.cache/wine \
    && wget https://dl.winehq.org/wine/wine-mono/4.6.4/wine-mono-4.6.4.msi \
        -O $HOME/.cache/wine/wine-mono-4.6.4.msi \
    && wget https://dl.winehq.org/wine/wine-gecko/2.47/wine_gecko-2.47-x86.msi \
        -O $HOME/.cache/wine/wine_gecko-2.47-x86.msi \
    && wget https://dl.winehq.org/wine/wine-gecko/2.47/wine_gecko-2.47-x86_64.msi \
        -O $HOME/.cache/wine/wine_gecko-2.47-x86_64.msi \
# Winetricks and cache files
    && wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
        -O /usr/bin/winetricks \
    && chmod +rx /usr/bin/winetricks \
    && mkdir -p $HOME/.cache/winetricks/win7sp1 \
    && wget https://download.microsoft.com/download/0/A/F/0AFB5316-3062-494A-AB78-7FB0D4461357/windows6.1-KB976932-X86.exe \
        -O $HOME/.cache/winetricks/win7sp1/windows6.1-KB976932-X86.exe \
# Clean up
    && apt-get autoremove -y \
        software-properties-common \
    && apt-get autoclean \
    && apt-get clean \
    && apt-get autoremove
VOLUME ["/home/wine"]
COPY ./entrypoint.sh /usr/bin/entrypoint
ENTRYPOINT ["/usr/bin/entrypoint"]
