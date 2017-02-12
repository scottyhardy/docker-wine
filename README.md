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

| Package                    | Purpose                                                                    |
| -------------------------- | -------------------------------------------------------------------------- |
| winehq-staging             | Staging branch of `wine`                                                   |
| winetricks                 | Script to assist with configuring your wine bottle and installing software |
| wget                       | Required for `winetricks`                                                  |
| cabextract                 | Required for `winetricks`                                                  |
| p7zip                      | Required for `winetricks`                                                  |
| unzip                      | Required for `winetricks`                                                  |
| wget                       | Required for `winetricks`                                                  |
| zenity                     | Required for `winetricks`                                                  |

In addition to the system packages, the following Windows installation files 
are also included so you don't need to download them each time:

| File                       | Purpose                                                                                 |
| -------------------------- | --------------------------------------------------------------------------------------- |
| wine-mono-4.6.4.msi        | [Mono](https://wiki.winehq.org/Mono) open-source .Net alternative                       |
| wine_gecko-2.47-x86.msi    | [Gecko](https://wiki.winehq.org/Gecko) 32 bit open-source Internet Explorer alternative |
| wine_gecko-2.47-x86_64.msi | [Gecko](https://wiki.winehq.org/Gecko) 64 bit open-source Internet Explorer alternative |

The Windows installation files are copied to `/home/wine/.cache/wine` as the `/home/wine` 
folder is set to home for all users.

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
    --volume="winehome:/home/wine" \
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
To replicate the `docker-wine` script from the GitHub repository, just copy and 
paste the following into a file named docker-wine and run 
`chmod +x ./docker-wine`:
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
    --volume="winehome:/home/wine" \
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

Volume container `winehome`
---------------------------
When the docker-wine image is instantiated with `./docker-wine` script or with 
the recommended `docker run` commands, the `/home/wine` folder is used as the home 
for all users.  If running as root it will use `/home/wine` for home and for other 
users a symbolic link is created in place of the user's home folder which 
points to `/home/wine`.

Using a volume container allows existing data from `/home/wine` on the docker-wine 
container to be replicated into the `winehome` volume on instantiation of the 
wine container. In this way the wine container which runs the `wine` commands 
can remain unchanged and any user environments created with `wine` will be 
stored separately.  This allows the docker-wine image to essentially be run in 
read-only mode and be removed after execution with `docker run --rm ...`. User 
data remains as long as the `winehome` volume persists and allows the 
docker-wine image to be switched out to a newer image at anytime.

You can manually create the `winehome` volume container by running:
```bash
docker volume create winehome
```
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

`entrypoint` script explained
-----------------------------
The `ENTRYPOINT` set for the docker-wine image is simply `/usr/bin/entrypoint`. 
This script is key to ensuring the wine container is run as the correct user 
and ownership of `/home/wine` is also set to the same user.

The contents of the `/usr/bin/entrypoint` script is:
```bash
#!/bin/bash

# $HOME = "/home/wine" - set by Dockerfile
# $USER = username of user who was passed to container via:
#           `docker run --env="USER"` ...

chown -R $USER:$USER $HOME
ln -s $HOME /home/$USER
if [ $# == 0 specified]; then
    su - $USER
else
    su -c "$*" - $USER
fi
```
Arguments specified after `./docker-wine` or after the 
`docker run ... docker-wine` command are also passed to this script. 
For example:
```bash
./docker-wine wine notepad.exe
```
The arguments `wine notepad.exe` are interpreted by the wine container as 
effectively overriding a `CMD` directive, which would normally follow the 
`ENTRYPOINT` command. The `ENTRYPOINT` command in this case is 
`/usr/bin/entrypoint` and the arguments are eventually run in the desired user 
context by the `su -c "$*" - $USER`

If no arguments are specified, it simply uses `su` to change to your username 
which was collected from the host machine by the `--env="USER"` argument. This 
in turn spawns a new `/bin/bash` session in your user context to interact with.

If you plan to use `scottyhardy/docker-wine` as a base for another Docker 
image, you can set up exactly the same functionality by adding the following to 
your Dockerfile:
```
FROM scottyhardy/docker-wine
... <your code here>
ENTRYPOINT ["/usr/bin/entrypoint"]
```
Or if you prefer to run a program by default you could use:
```
ENTRYPOINT ["/usr/bin/entrypoint", "wine", "notepad.exe"]
```
Or if you want to be able to run a program by default but still be able to 
override it easily you could use:
```
ENTRYPOINT ["/usr/bin/entrypoint"]
CMD ["wine", "notepad.exe"]
```
