#!/bin/bash

chown -R $USER:$USER $HOME
ln -s $HOME /home/$USER
if [ $# == 0 ]; then
    su - $USER
else
    su -c "$*" - $USER
fi