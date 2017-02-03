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
ENV HOME=/home/wine
RUN \
    mkdir -p $HOME \
    && chmod 2777 $HOME \
    && wget http://dl.winehq.org/wine/wine-mono/4.6.4/wine-mono-4.6.4.msi \
        -O $HOME/wine-mono-4.6.4.msi \
    && wget http://dl.winehq.org/wine/wine-gecko/2.47/wine_gecko-2.47-x86.msi \
        -O $HOME/wine_gecko-2.47-x86.msi
RUN chmod 777 $HOME/*.msi
VOLUME ["/home/wine "]
WORKDIR $HOME
CMD ["/bin/bash"]
