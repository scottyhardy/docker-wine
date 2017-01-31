FROM ubuntu:16.04
RUN apt-get update \
    && apt-get install -y \
        software-properties-common \
        wget \
    && dpkg --add-architecture i386 \
    && add-apt-repository ppa:wine/wine-builds \
    && apt-get update \
    && apt-get install -y --install-recommends winehq-staging \
    && wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
        -O /usr/bin/winetricks \
    && chmod +rx /usr/bin/winetricks
CMD ["/bin/bash"]
