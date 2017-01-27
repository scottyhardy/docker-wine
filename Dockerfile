FROM ubuntu:16.04
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y software-properties-common \
    && add-apt-repository ppa:wine/wine-builds \
    && apt-get update
RUN apt-get install -y --install-recommends winehq-staging wget
ADD https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks /usr/bin/winetricks 
RUN chmod +x /usr/bin/winetricks
CMD ["/bin/bash"]
