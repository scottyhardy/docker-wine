docker-wine
===========

Included in the [scottyhardy/docker-wine GitHub repository](https://github.com/scottyhardy/docker-wine) 
are scripts to enable you to build a Docker container that runs Wine. The 
container is based on Ubuntu 16.04 and uses the Wine Staging branch (latest/
less stable) and also includes the latest version of `winetricks`. Included 
below are instructions for running the `docker-wine` container with X11 
forwarding to display graphics in the local user's session without needing to 
compromise xhost security.

Creating your own docker-wine image
-----------------------------------
First, clone the repository from GitHub:
```bash
git clone https://github.com/scottyhardy/docker-wine.git
```

To build the container, simply run:
```bash
make
```

To run the container and start an interactive session with /bin/bash run either:
```bash
make run
```
or use the `docker-wine` script as described below.

Running from Docker Hub image
-----------------------------
The recommended command for running docker-wine securely is:
```bash
docker run -it \
    --rm \
    --env="DISPLAY" \
    --volume="/etc/group:/etc/group:ro" \
    --volume="/etc/passwd:/etc/passwd:ro" \
    --volume="/etc/shadow:/etc/shadow:ro" \
    --volume="/tmp/.X11-unix:/tmp/.X11-unix:ro" \
    --volume="$HOME/.docker-wine:$HOME" \
    --workdir="$HOME" \ 
    --user="`id -u`:`id -g`" \
    --name="wine" \
    scottyhardy/docker-wine <Additional arguments e.g. wine notepad.exe>
```
This includes a lot of volumes on the local machine, but these are so that the 
container runs in the context of the user that executed the `docker run` 
command.  This in turn means that the X11 redirection to the local machine can 
be performed without needing to modify `xhost` permissions.

The minimum command you'll need to run the image with graphical support is:
```bash
docker run -it \
    --env="DISPLAY" \
    --volume="/tmp/.X11-unix:/tmp/.X11-unix:ro" \
    scottyhardy/docker-wine
```
First off, this will mean all data is stored in your container.  That's fine if 
you're trying to achieve total abstraction from the host machine but not great 
if you're looking to make your containers ephemeral.
Also, since Docker containers run as root by default it means running the above
code will likely result in a bunch of errors as soon as you try to run anything 
that tries to display graphics, unless you modify xhost permissions:
```
root@d7dccdc39da1:/# wine notepad.exe
wine: created the configuration directory '/root/.wine'
...
err:winediag:nulldrv_CreateWindow Application tried to create a window, but no driver could be loaded.
err:winediag:nulldrv_CreateWindow Make sure that your X server is running and that $DISPLAY is set correctly.
```
You can get around this by modifying xhost permissions on your local machine by running:
```bash
xhost +
```
or slightly more securely:
```bash
xhost +local:root
```
Either of these are huge security concerns as it opens the possibility for 
someone to run an application on your screen and capture input.  At worst if 
you do use the above you should at least wrap a script around the `docker run` 
command that disables the security hole after execution:
```bash
xhost -
```
or if you used the slightly more secure alternative:
```
xhost -local:root
```

Manually creating `docker-wine` script
--------------------------------------
To replicate the `docker-wine` script from the GitHub repository, just copy and paste 
the following into a file named docker-wine and run `chmod +x ./docker-wine`:
```bash
#!/bin/bash

DOCKERWINEHOME=${DOCKERWINEHOME:-.docker-wine}
[ ! -d "$HOME/$DOCKERWINEHOME" ] && mkdir -p "$HOME/$DOCKERWINEHOME"

docker run -it \
    --rm \
    --env="DISPLAY" \
    --volume="/etc/group:/etc/group:ro" \
    --volume="/etc/passwd:/etc/passwd:ro" \
    --volume="/etc/shadow:/etc/shadow:ro" \
    --volume="/tmp/.X11-unix:/tmp/.X11-unix:ro" \
    --volume="$HOME/$DOCKERWINEHOME:$HOME" \
    --workdir="$HOME" \
    --user="`id -u`:`id -g`" \
    --name="wine" \
    scottyhardy/docker-wine $*
```

Running the `docker-wine` script
--------------------------------
When the container is run with the `docker-wine` script, you can override the 
default interactive bash session by adding `wine`, `winetricks`, `winecfg` or 
any other valid commands with their associated arguments:
```bash
./docker-wine wine notepad.exe
```
```bash
./docker-wine winecfg
```
```bash
./docker-wine winetricks msxml3 dotnet40 win7
```

Local Data Storage
------------------
By default, running `./docker-wine` maps a volume on the local machine to 
`$HOME/.docker-wine` which will hold all data created whenever you run any wine 
commands with the `docker-wine` container.  You can change this default 
location with the `DOCKERWINEHOME=<folder name>` environment variable to create 
additional docker-wine environments under `$HOME/<folder name>`:
```bash
DOCKERWINEHOME=.my-wine-home ./docker-wine
```
If you plan to run multiple commands with the alternative environment, don't 
forget to `export` your `DOCKERWINEHOME` value or else you will need to include 
it every time you run `./docker-wine`:
```bash
export DOCKERWINEHOME=.no_place_like_home
./docker-wine wine explorer.exe           # <-- Uses local folder $HOME/.no_place_like_home
                                          #     for storing container volume
```
It does not include any changes to files outside of the user's home folder in 
the container, so it is not recommended to change any of these unless you 
create additional volume mounts. 
