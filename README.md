# docker-wine

Included in the [scottyhardy/docker-wine GitHub repository](https://github.com/scottyhardy/docker-wine) are scripts to enable you to build a Docker container that runs `wine`. The  container is based on Ubuntu 16.04 and includes the latest version of `winetricks`. Included below are instructions for running the `docker-wine` container with X11 forwarding to display graphics in the local user's session without needing to compromise xhost security.

## Creating your own docker-wine image

First, clone the repository from GitHub:

```bash
git clone https://github.com/scottyhardy/docker-wine.git
```

To build the container, simply run:

```bash
make
```

To run the container and start an interactive session with `/bin/bash` run either:

```bash
make run
```

or use the `docker-wine` script as described below.

## Running from Docker Hub image

The recommended commands for running docker-wine securely are:

```bash
docker volume create winehome

docker run -it \
    --rm \
    --env="DISPLAY" \
    --volume="$XAUTHORITY:/root/.Xauthority:ro" \
    --volume="winehome:/home/wine" \
    --net="host" \
    --name="wine" \
    scottyhardy/docker-wine <Additional arguments e.g. wine notepad.exe>
```

This assumes the `$XAUTHORITY` environment variable is set to the location of the MIT magic cookie.  If not set, the default location is in the user's home as `~/.Xauthority`.  This file is required to allow the container to write to the current user's X session. For this to work you also need to include the `--net=host` argument when executing `docker run` to use the host's network stack which includes the X11 socket.

## Running the `docker-wine` script

When the container is run with the `docker-wine` script, you can override the default interactive bash session by adding `wine`, `winetricks`, `winecfg` or any other valid commands with their associated arguments:

```bash
./docker-wine wine notepad.exe
```

```bash
./docker-wine winecfg
```

```bash
./docker-wine winetricks msxml3 dotnet40 win7
```

## Volume container `winehome`

When the docker-wine image is instantiated with `./docker-wine` script or with the recommended `docker volume create` and `docker run` commands, the contents of the `/home/wine` folder is copied to the `winehome` volume container on instantiation of the `wine` container.

Using a volume container allows the `wine` container to remain unchanged and safely removed after every execution with `docker run --rm ...`.  Any user environments created with `wine` will be stored separately and user data will persist as long as the `winehome` volume is not removed.  This effectively allows the `docker-wine` image to be swapped out for a newer version at anytime.

You can manually create the `winehome` volume container by running:

```bash
docker volume create winehome
```

If you don't want the volume container to persist after running `./docker-wine`, just add `--rm` as your first argument.
e.g.

```bash
./docker-wine --rm wine notepad.exe

```

Alternatively you can manually delete the volume container by using:

```bash
docker volume rm winehome
```

## `ENTRYPOINT` script explained

The `ENTRYPOINT` set for the docker-wine image is simply `/usr/bin/entrypoint`. This script is key to ensuring the user's `.Xauthority` file is copied from `/root/.Xauthority` to `/home/wine/.Xauthority` and ownership of the file is set to the `wine` user each time the container is instantiated.

Arguments specified after `./docker-wine` or after the `docker run ... docker-wine` command are also passed to this script to ensure it is executed as the `wine` user.

For example:

```bash
./docker-wine wine notepad.exe
```

The arguments `wine notepad.exe` are interpreted by the wine container to override the `CMD` directive, which otherwise simply runs `/bin/bash` to give you an interactive bash session as the `wine` user in the container.

## Using docker-wine in your own Dockerfile

If you plan to use `scottyhardy/docker-wine` as a base for another Docker image, you should set up the same entrypoint to ensure you run as the `wine` user and X11 graphics continue to function by adding the following to your `Dockerfile`:

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
