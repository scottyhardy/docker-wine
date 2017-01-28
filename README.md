docker-wine
===========

Using the scripts in this repo, you will be able to build a Docker container 
that runs Wine.  The image is based on Ubuntu 16.04 and uses the Wine Staging 
branch (latest/less stable) and also includes the latest version of `winetricks`

How to use the scripts
----------------------
To build the container, simply run:
```bash
make
```

To run the container and start an interactive session with /bin/bash run either:
```bash
make run
```
or
```bash
./docker-wine
```
When the container is run with the supplied `docker-wine` script, you can also 
override the default `/bin/bash` command with `wine`, `winetricks`, `winecfg` 
or any other valid commands with their associated arguments.
```bash
./docker-wine wine notepad.exe
```
```bash
./docker-wine winecfg
```
```bash
./docker-wine winetricks msxml3 dotnet40 win7
```

Data Storage
------------
By default, running `docker-wine` maps a volume on the local machine to 
`$HOME/.docker-wine` which will hold all data created when you run the 
`docker-wine` container.  You can change this default location with  the 
`DOCKERWINEHOME` environment variable.
```bash
DOCKERWINEHOME=.my-wine-home ./docker-wine
```