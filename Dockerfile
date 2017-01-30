FROM ubuntu:16.04
ADD https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks /usr/bin/winetricks 
RUN chmod +rx /usr/bin/winetricks \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y \
        software-properties-common \
        wget \
    && add-apt-repository ppa:wine/wine-builds \
    && apt-get update \
    && apt-get install -y --install-recommends winehq-staging
CMD ["/bin/bash"]
