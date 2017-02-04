docker-wine
===========

Included in the [scottyhardy/docker-wine GitHub repository](https://github.com/scottyhardy/docker-wine) 
are scripts to enable you to build a Docker container that runs Wine. The 
container is based on Ubuntu 16.04 and uses the Wine Staging branch (latest/
less stable) and also includes the latest version of `winetricks`. Included 
below are instructions for running the `docker-wine` container with X11 
forwarding to display graphics in the local user's session without needing to 
compromise xhost security.

Included packages
-----------------
| Package                    | Purpose                                        |
| -------------------------- | ---------------------------------------------- |
| software-properties-common | Required for `add-apt-repository`              |
| winehq-staging             | Staging branch of `wine`                       |
| winetricks                 | Script to assist with configuring your wine bottle and installing software |
| wget                       | Required for `winetricks` to download binaries |

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
The recommended commands for running docker-wine securely are:
```bash
docker volume create winehome

docker run -it \
    --rm \
    --env="DISPLAY" \
    --env="USER" \
    --volume="/etc/group:/etc/group:ro" \
    --volume="/etc/passwd:/etc/passwd:ro" \
    --volume="/etc/shadow:/etc/shadow:ro" \
    --volume="/tmp/.X11-unix:/tmp/.X11-unix:ro" \
    --volume="winehome:/wine" \
    --name=wine \
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
Since Docker containers run as root by default it means running the above
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

Manually creating `docker-wine` script for use with Docker Hub image
--------------------------------------------------------------------
To replicate the `docker-wine` script from the GitHub repository, just copy and paste 
the following into a file named docker-wine and run `chmod +x ./docker-wine`:
```bash
#!/bin/bash

case $1 in
    --rm)
        echo "Auto-removing volume container 'winehome' after completing action..."
        shift
        $0 "$@"
        exitcode=$?
        docker volume rm winehome 2>&1 >/dev/null
        echo "Removed 'winehome' volume container"
        exit $exitcode
        ;;
    --help)
        echo "Usage: $0 [--rm] [command] [arguments]..."
        echo "e.g."
        echo "    $0"
        echo "    $0 --rm"
        echo "    $0 wineboot --init"
        echo "    $0 --rm wine explorer.exe"
        exit 0
        ;;
esac

if ! docker volume ls | grep -q winehome; then
    echo "Creating volume container 'winehome'..."
    docker volume create winehome
fi

docker run -it \
    --rm \
    --env="DISPLAY" \
    --env="USER" \
    --volume="/etc/group:/etc/group:ro" \
    --volume="/etc/passwd:/etc/passwd:ro" \
    --volume="/etc/shadow:/etc/shadow:ro" \
    --volume="/tmp/.X11-unix:/tmp/.X11-unix:ro" \
    --volume="winehome:/wine" \
    --name=wine \
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

Volume Container
----------------
By default, running `./docker-wine` creates a volume container named `winehome` 
and will have a suffix of `-<branch name>` if not running from the master 
branch. This volume contains the folder `/wine` which is the common home 
folder used no matter which user the container is running as.
Within the volume container, some files required for setting up your wine 
prefix will be replicated from the `docker-wine` container.  In this way the 
actual wine program files will be separated from the user data so it can be 
switched out any time to a newer image without losing any data.

If you don't want the volume container to persist after running `./docker-wine`, 
just add `--rm` as your first argument.
e.g.
```bash
./docker-wine --rm wine notepad.exe
```
Alternatively you can manually delete the volume container by using:
```bash
docker volume rm winehome
```