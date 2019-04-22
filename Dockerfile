FROM ubuntu:16.04 as wine-base
# Prevents annoying debconf errors during builds
RUN export DEBIAN_FRONTEND="noninteractive" \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
# Required for adding repositories
        software-properties-common \
# Required for wine
        gosu \
        winbind \
# Required for winetricks
        cabextract \
        p7zip \
        unzip \
        wget \
        zenity \
# Install wine
    && add-apt-repository ppa:wine/wine-builds \
    && apt-get update \
    && apt-get install -y --install-recommends winehq-staging \
# Clean up
    && apt-get autoremove -y \
        software-properties-common \
    && rm -rf /var/lib/apt/lists/*


FROM wine-base as wine-cache
# Download wine cache files
RUN mkdir -p /home/wine/.cache/wine \
    && wget https://dl.winehq.org/wine/wine-mono/4.6.4/wine-mono-4.6.4.msi \
        -O /home/wine/.cache/wine/wine-mono-4.6.4.msi \
    && wget https://dl.winehq.org/wine/wine-gecko/2.47/wine_gecko-2.47-x86.msi \
        -O /home/wine/.cache/wine/wine_gecko-2.47-x86.msi \
    && wget https://dl.winehq.org/wine/wine-gecko/2.47/wine_gecko-2.47-x86_64.msi \
        -O /home/wine/.cache/wine/wine_gecko-2.47-x86_64.msi \
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
