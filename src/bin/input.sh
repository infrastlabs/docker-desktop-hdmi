#!/bin/bash

# input.sh @entrypoint.sh
# add input devices and their events to X11 configuration
mkdir -p /etc/X11/xorg.conf.d/
conf=/etc/X11/xorg.conf.d/10-input.conf
rm -f $conf
# create new input device file
cat > $conf <<_EOF_
Section "ServerFlags"
     Option "AutoAddDevices" "False"
EndSection
_EOF_

cd /dev/input
for input in event*
do
cat >> $conf <<_EOF_
    Section "InputDevice"
    Identifier "$input"
    Option "Device" "/dev/input/$input"
    Option "AutoServerLayout" "true"
    Driver "evdev"
EndSection
_EOF_
done

echo cat $conf
cat $conf
