#!/bin/bash

# Copy and take ownership of .Xauthority
if [ -f /root/.Xauthority ]; then
    cp /root/.Xauthority /home/wine
    chown wine:wine /home/wine/.Xauthority
fi

exec gosu wine "$@"
