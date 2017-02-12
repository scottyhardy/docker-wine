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
    --volume="$HOME/.Xauthority:/home/wine/.Xauthority:ro" \
    --volume="winehome:/home/wine" \
    --net="host" \
    --name="wine" \
    scottyhardy/docker-wine <Additional arguments e.g. wine notepad.exe>
```
This includes the user's `~/.Xauthority` file which contains the magic cookie 
required to write to the current user's X session.  For this to work you also 
need to include the `--net=host` argument when executing `docker run` to use 
the host's network stack which includes the X11 socket.

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

if ! docker volume ls -qf "name=winehome" | grep -q "winehome"; then
    echo "Creating volume container 'winehome'..."
    docker volume create winehome
else
    echo "Using existing volume container 'winehome'..."
fi

docker run -it \
    --rm \
    --env="DISPLAY" \
    --volume="$HOME/.Xauthority:/home/wine/.Xauthority:ro" \
    --volume="winehome:/home/wine" \
    --net="host" \
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

Volume container `winehome`
---------------------------
When the docker-wine image is instantiated with `./docker-wine` script or with 
the recommended `docker volume create` and `docker run` commands, the contents 
of the `/home/wine` folder is copied to the `winehome` volume container on 
instantiation of the `wine` container.

Using a volume container allows the `wine` container to remain unchanged and be 
safely removed after every execution with `docker run --rm ...`.  Any user 
environments created with `wine` will be stored separately and user data 
persists as long as the `winehome` volume is not removed.  This effectively 
allows the `docker-wine` image to be switched out to a newer image at anytime.

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
