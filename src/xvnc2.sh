#!/bin/bash
# replace docker-x11base/rootfs/src/xvnc.sh
cmd=$1
offsetLimitIndex=$2
offsetLimitIndex=${offsetLimitIndex:-99}

case "$cmd" in
xvnc)
    rm -f /tmp/.X$offsetLimitIndex-lock #clear first, avoid dead-lock
    exec Xvnc -ac :$offsetLimitIndex -listen tcp -rfbauth=/etc/xrdp/vnc_pass -depth 16 -BlacklistThreshold=3 -BlacklistTimeout=1
    ;;
xorg)
    sudo bash /usr/local/bin/input.sh
    # dispNum=${DISPLAY#*:}; dispNum=${dispNum%.*}
    dispNum=$offsetLimitIndex
    sudo rm -f /tmp/.X${dispNum}-lock
    sudo Xorg :$dispNum vt$(($dispNum+7)) #root-xorg
    ;;
x11vnc)
    export DISPLAY=:$offsetLimitIndex

    # /etc/xrdp/vnc_pass; VNC_PASS_RO:x11vnc non-support?
    port1=$(expr 5900 + $offsetLimitIndex)
    exec x11vnc -display :$offsetLimitIndex -rfbport $port1 -rfbauth /etc/xrdp/vnc_pass -forever -shared -capslock   -nomodtweak -noxdamage  -noshm  -noxrecord
    # x11vnc -display :32 -forever
    # x11vnc -forever -loop -repeat -shared -capslock -nomodtweak -noxdamage -rfbport 5900
    # x11vnc -forever -loop -repeat -shared -capslock -nomodtweak -noxdamage -rfbport 5900 -auth guess -rfbauth ~/.vnc/passwd
      # blackScreen tty-switchd, dseek: -noxrecord[加与不加:手机ip:52081查看,tty9激活时可看屏/出tty9则都黑屏]; -rawfb /dev/fb0 [always black]
    ;;
chansrv)
    export DISPLAY=:$offsetLimitIndex #:2
    exec xrdp-chansrv
    ;;
pulse)
    # port=$(expr 4700 + $offsetLimitIndex) #4713
    # mkdir -p /tmp/.headless; pa="/tmp/.headless/pulse-$port.pa"
    # cat /etc/pulse/default.pa > $pa; sed -i "s/4700/$port/g" $pa
    # exec pulseaudio --exit-idle-time=-1 -nF $pa
    #udev: ref docs/data/etc_initd_udev
    sleep 1
    sudo udevadm info --cleanup-db
    sudo udevadm trigger --type=subsystems --action=add
    sudo udevadm trigger --type=devices --action=add
    sudo udevadm settle
    # sudo udevadm control --reload-rules

    sudo sed -i "s/^load-module module-console-kit/#load-module module-console-kit/g" /etc/pulse/default.pa #for: core-debian-9
    sudo rm -rf /tmp/pulse-*
    # echo "load-module module-alsa-sink device=plughw:0,3" |sudo tee /etc/pulse/default.pa
    exec pulseaudio --exit-idle-time=-1 #-n ##-n => dot't load default conf
    # pulseaudio &
    # sleep 2; pavucontrol > /dev/null 2>&1 &
    # pactl load-module module-alsa-sink device=plughw:0,0 #weipai_s11: 0,0
    ;;    
# parec)
#     echo "sleep 2.5" && sleep 2.5 #wait
#     src="-d xrdp-sink.monitor"
#     url="localhost:$PORT_VNC/bcs/PULSE.mp3?stream=true&advertise=true"
#     exec parec --format=s16le $src |lame -r -ab 52 - - \
#         | exec curl -s -k -H "Transfer-Encoding: chunked" -X POST -T -  "$url"
#     ;;
dbus)
    sudo mkdir -p /var/run/dbus/
    export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/var/run/dbus/system_bus_socket
    sudo rm -f /run/dbus/pid
    sudo dbus-daemon --system --nofork
    # sleep 2
    # xfce4-power-manager &
    # NetworkManager &
    ;;
udev)
    # udev: for pulseaudio, NetworkManager
    sudo mkdir -p /run/udev
    sudo rm -rf /run/udev/control #sock?
    sudev=/lib/systemd/systemd-udevd
    test -s $sudev && sudo $sudev #--daemon; ##ubt18非软链:/usr/lib> /lib
    # eudev@alpine
    sudo /sbin/udevd #--daemon 
    # dpkg -l |grep systemd #cnt4, same with ap34-deb9-host
    # find /run/udev -type f |wc #cnt445
    # udevadm trigger
    ;;
opencode)
    cd /_ext
    bash oc_start.sh
    ;;
cloudcli)
    sleep 1
    cd /_ext/down/node-v20.19.5-linux-x64/bin
    export PATH=$(pwd):$PATH
    node cloudcli
    ;;
nm)
    sudo NetworkManager --no-daemon
    ;;
*)
    echo "please call with: xvnc.sh xvnc/chansrv/pulse/parec xx"
    ;;
esac
