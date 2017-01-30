FROM ubuntu:16.04
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y \
        software-properties-common \
        wget \
    && wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
        -O /usr/bin/winetricks \
    && chmod +rx /usr/bin/winetricks \
    && add-apt-repository ppa:wine/wine-builds \
    && apt-get update \
    && apt-get install -y --install-recommends winehq-staging
CMD ["/bin/bash"]
