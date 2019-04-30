#!/bin/bash

# Copy and take ownership of .Xauthority
if [ -f /root/.Xauthority ]; then
    cp /root/.Xauthority /home/wineuser
    chown wineuser:wineuser /home/wineuser/.Xauthority
fi

exec gosu wineuser "$@"
