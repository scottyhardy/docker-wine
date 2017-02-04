#!/bin/bash

# $HOME = "/wine" - set by Dockerfile
# $USER = username of user who was passed to container via:
#           `docker run --env="USER"` ...

chown -R $USER:$USER $HOME
ln -s $HOME /home/$USER
if [ $# == 0 ]; then
    su - $USER
else
    su -c "$*" - $USER
fi
