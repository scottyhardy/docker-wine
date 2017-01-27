FROM ubuntu:16.04
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y software-properties-common \
    && add-apt-repository ppa:wine/wine-builds \
    && apt-get update
RUN apt-get install -y --install-recommends winehq-staging wget
RUN wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
    && install ./winetricks /usr/bin/winetricks 
CMD ["/bin/bash"]
