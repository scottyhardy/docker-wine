#!/bin/bash

# Copy and take ownership of .Xauthority
if [ -f /root/.Xauthority ]; then
    cp /root/.Xauthority /home/wine
    chown wine:wine /home/wine/.Xauthority
fi

# If no arguments, just su to 'wine' which will start /bin/bash
if [ $# == 0 ]; then
    su - wine

# Otherwise, run the command line arguments as 'wine'
else
    su -c "$*" - wine
fi
