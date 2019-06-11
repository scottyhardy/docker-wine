# docker-wine ![ ](https://raw.githubusercontent.com/scottyhardy/docker-wine/2.0.0/images/logo_small.png)

![Docker Pulls](https://img.shields.io/docker/pulls/scottyhardy/docker-wine.svg?style=social)
![Docker Stars](https://img.shields.io/docker/stars/scottyhardy/docker-wine.svg?style=social)
[![GitHub forks](https://img.shields.io/github/forks/scottyhardy/docker-wine.svg?style=social)](https://github.com/scottyhardy/docker-wine/network)
[![GitHub stars](https://img.shields.io/github/stars/scottyhardy/docker-wine.svg?style=social)](https://github.com/scottyhardy/docker-wine/stargazers)

* [About docker-wine](#about-docker-wine)
* [Getting Started](#getting-started)
  * [Download the docker-wine script](#download-the-docker-wine-script)
  * [Run the docker-wine script](#run-the-docker-wine-script)
  * [Run on macOS](#run-on-macos)
* [Build and run locally on your PC](#build-and-run-locally-on-your-pc)
* [Volume container winehome](#volume-container-winehome)
* [ENTRYPOINT script explained](#entrypoint-script-explained)
* [Using docker-wine in your own Dockerfile](#using-docker-wine-in-your-own-dockerfile)
* [Troubleshooting](#troubleshooting)

## About docker-wine

The `docker-wine` image was created so I could experiment with [Wine](https://www.winehq.org) while learning the ropes for using Docker containers. The image is based on Ubuntu 18.04 and includes Wine version 4.0.1 ([stable branch](https://wiki.winehq.org/Wine_User%27s_Guide#Wine_from_WineHQ)) and the latest version of [Winetricks](https://wiki.winehq.org/Winetricks) to help manage your Wine bottles.

Included below are instructions for running the `docker-wine` container that allows you to use the Docker host's X11 session to display graphics and its PulseAudio server for sound through the use of UNIX sockets.

The source code is freely available from the [scottyhardy/docker-wine GitHub repository](https://github.com/scottyhardy/docker-wine) for you to build the image yourself and contributions are welcome.

## Getting Started

Using the `docker-wine` script is the easiest way to get started and should be all you need for Linux OSes.  There's a few extra hurdles to get it working on macOS, so there's instructions on what you need to do at [Run on macOS](#run-on-macos).

### Download the docker-wine script

On Linux:

```bash
sudo wget https://raw.githubusercontent.com/scottyhardy/docker-wine/master/docker-wine -O /usr/local/bin/docker-wine
sudo chmod +x /usr/local/bin/docker-wine
```

On macOS:

```bash
curl https://raw.githubusercontent.com/scottyhardy/docker-wine/master/docker-wine -o /usr/local/bin/docker-wine
chmod +x /usr/local/bin/docker-wine
```

### Run the docker-wine script

When the container is run with the `docker-wine` script, you can override the default interactive bash session by adding `wine`, `winetricks`, `winecfg` or any other valid commands with their associated arguments:

```bash
docker-wine wine notepad.exe
```

```bash
docker-wine winecfg
```

```bash
docker-wine winetricks msxml3 dotnet40 win7
```

### Run on macOS

Unfortunately there's a lot of additional barriers when attempting to run containers on macOS.  At time of writing, it is not possible to directly mount UNIX sockets like you can do in Linux. There's a few different ways this problem can be solved, but essentially it comes down to using TCP sockets or a remote desktop protocol such as VNC.

Below are instructions for using TCP sockets on macOS but unfortunately performance is way slower than with UNIX sockets on Linux, plus I haven't managed to get audio working yet. If you're serious about using a Windows application on macOS then this is probably not the best solution. If you'd just like to give it a go for shits and giggles, then this should be enough to get you started.

#### Install homebrew

```bash
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

#### Install XQuartz

```bash
brew install xquartz
```

#### Start XQuartz

```bash
open -a xquartz
```

#### Enable network clients in XQuartz Preferences

Go to **XQuartz** -> **Preferences...**

Or use shortcut keys: **&#8984;,**

On the **Security** tab, tick the option **Allow connections from network clients**

![XQuartz Preferences screenshot](https://raw.githubusercontent.com/scottyhardy/docker-wine/2.0.0/images/xquartz_prefs.png)

#### IMPORTANT! Restart XQuartz

Go to **XQuartz** -> **Quit X11**

Or use shortcut keys: **&#8984;Q**

*Note: If graphics are not working and you get errors that X11 is not available it's probably because you missed this step.*

#### Run container with docker-wine script

Jump back up to [Run the docker-wine script](#run-the-docker-wine-script) and continue from there.

## Build and run locally on your PC

First, clone the repository from GitHub:

```bash
git clone https://github.com/scottyhardy/docker-wine.git
```

To build the container, simply run:

```bash
make
```

To run the container and start an interactive session with `/bin/bash` run:

```bash
make run
```

or use the `docker-wine` script with the `--local` switch.:

```bash
docker-wine --local
```

## Volume container winehome

When the docker-wine image is instantiated with `docker-wine` script, the contents of the `/home/wineuser` folder is copied to the `winehome` volume container on instantiation of the `wine` container.

Using a volume container allows the `wine` container to remain unchanged and safely removed after every execution with `docker run --rm ...`.  Any user environments created with `docker-wine` will be stored separately and user data will persist as long as the `winehome` volume is not removed.  This effectively allows the `docker-wine` image to be swapped out for a newer version at anytime.

You can manually create the `winehome` volume container by running:

```bash
docker volume create winehome
```

If you don't want the volume container, you can delete it by using:

```bash
docker volume rm winehome
```

## ENTRYPOINT script explained

The `ENTRYPOINT` set for the docker-wine image is simply `/usr/bin/entrypoint`. This script is key to ensuring the user's `.Xauthority` file is copied from `/root/.Xauthority` to `/home/wineuser/.Xauthority` and ownership of the file is set to `wineuser` each time the container is instantiated.

Arguments specified after `docker-wine` are also passed to this script to ensure it is executed as `wineuser`.

For example:

```bash
docker-wine wine notepad.exe
```

The arguments `wine notepad.exe` are interpreted by the `wine` container to override the `CMD` directive, which otherwise simply runs `/bin/bash` to give you an interactive bash session as `wineuser` within the container.

## Use docker-wine image in a Dockerfile

If you plan to use `scottyhardy/docker-wine` as a base for another Docker image, you should set up the same entrypoint to ensure you run as `wineuser` and X11 graphics continue to function by adding the following to your `Dockerfile`:

```dockerfile
FROM scottyhardy/docker-wine:latest
... <your code here>
ENTRYPOINT ["/usr/bin/entrypoint"]
```

Or if you prefer to run a program by default you could use:

```dockerfile
ENTRYPOINT ["/usr/bin/entrypoint", "wine", "notepad.exe"]
```

Or if you want to be able to run a program by default but still be able to override it easily you could use:

```dockerfile
ENTRYPOINT ["/usr/bin/entrypoint"]
CMD ["wine", "notepad.exe"]
```

## Troubleshooting

To test video, try opening Notepad:

```bash
docker-wine wine notepad
```

To test sound, try using `pacat` just to confirm PulseAudio is working:

```bash
docker-wine pacat -vv /dev/random
```
