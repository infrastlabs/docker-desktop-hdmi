#!/bin/bash

# SIGNAL-handler
term_handler() {

  # echo "stopping x server ..."
  # pidxserver=$(pidof "Xorg") 

  # sudo kill -SIGTERM "$pidxserver"
  # tail --pid=$pidxserver -f /dev/null

  # echo "terminating ssh ..."
  # sudo /etc/init.d/ssh stop

  exit 143; # 128 + 15 -- SIGTERM
}
# on callback, stop all started processes in term_handler
trap 'kill ${!}; term_handler' SIGINT SIGKILL SIGTERM SIGQUIT SIGTSTP SIGSTOP SIGHUP


function x11baseAlter(){
  # USERMOD
  # cat /etc/group |egrep "sudo|tty|video|input|audio|pulse" ##all-existed
  # adduser USER GROUP
  # adduser $u1 sudo
  # adduser $u1 tty
  # adduser $u1 video
  # addgroup input; adduser $u1 input  
  # usermod -a -G audio $u1
  # usermod -a -G pulse $u1
  # usermod -a -G pulse-access $u1
  u1=headless
  vals=$(echo "sudo|tty|video|input|audio|pulse" |sed "s/|/ /g"); arr=($vals)
  for one in "${arr[@]}"; do
    echo "usermod -a -G $one"; usermod -a -G $one $u1
  done
  groups $u1 #view  

  # LOCALE
  if [ ! -z "$L" ]; then #export LANG,LANGUAGE
      charset=${L##*.}; test "$charset" == "$L" && charset="UTF-8" || echo "charset: $charset"
      lang_area=${L%%.*}
      export LANG=${lang_area}.${charset}
      export LANGUAGE=${lang_area}:en #default> en
      echo "====LANG: $LANG, LANGUAGE: $LANGUAGE=========================="
  fi  

  # Dump environment variables
  # https://hub.fastgit.org/hectorm/docker-xubuntu/blob/master/scripts/bin/container-init
  # sudo -V > /dev/null 2>&1; test "0" == "$?" && sudo=sudo
  # export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  # export DISPLAY=:$VNC_OFFSET
  cat /etc/environment
  env \
  |grep -Ev '_PASS.*|^SHLVL|^HOSTNAME|^PWD|^OLDPWD|^HOME|^USER|^SHELL|^TERM' \
  |grep -Ev "LOC_|DEBIAN_FRONTEND|LOCALE_INCLUDE" | sort |$sudo tee /etc/environment2 > /dev/null 2>&1
  # source /.env
  : |$sudo tee /.env
  cat /etc/environment2 |while read one; do echo "export $one" | $sudo tee -a /.env > /dev/null 2>&1; done
  echo "export XMODIFIERS=@im=ibus" |$sudo tee -a /.env;\
  echo "export GTK_IM_MODULE=ibus" |$sudo tee -a /.env;\
  echo "export QT_IM_MODULE=ibus" |$sudo tee -a /.env;
  # \
  echo "export XMODIFIERS=@im=ibus" |$sudo tee -a /etc/profile;\
  echo "export GTK_IM_MODULE=ibus" |$sudo tee -a /etc/profile;\
  echo "export QT_IM_MODULE=ibus" |$sudo tee -a /etc/profile;
  # source /.env; #setEnv ##source @headless

  # setlocale: bin/setlocale
  lock=/.1stinit.lock
  test -f "$lock" && echo "[locale] none-first, skip." || setlocale #locale只首次设定(arm下单核cpu占满, 切换-e L=zh_HK时容器重置)
  touch $lock  
}

# x11base.headless
if [ -d "/home/headless" ]; then
  if [ "" == "$1" ]; then
    x11baseAlter
    su - headless -c "bash /entrypoint2.sh skip-loop-call"
    exit 0
  fi
fi

#remove locks in case desktop crashed
sudo rm /tmp/.X0-lock &>/dev/null || true
# sudo rm  -fr ~/.Xauthority; touch ~/.Xauthority; chmod 777 ~/.Xauthority

# add input devices and their events to X11 configuration
sudo bash /usr/local/bin/input.sh

# #set ALSA sound to HDMI output
# sudo amixer cset numid=3 2     
# sudo amixer cset numid=1 100%


test -f /.env && source /.env; #setEnv
#set environment variables
# export DISPLAY=:0.0
# export XAUTHORITY=~/.Xauthority

# run applications in the background
echo "starting X on display 0 ..."
# /usr/bin/startx -- :0 &
# split: Xorg+startxfce4
test -z "$START_SESSION" && export START_SESSION=startfluxbox
test -z "$DISPLAY" && export DISPLAY=:1
dispNum=${DISPLAY#*:}; dispNum=${dispNum%.*}
sudo rm -f /tmp/.X${dispNum}-lock
#sudo Xorg $DISPLAY vt8 -novtswitch &
sudo Xorg $DISPLAY vt$(($dispNum+7)) &
sleep 2; $START_SESSION > /dev/null 2>&1 &

# if before Xorg, will fail?
echo "starting dbus ..."
sudo mkdir -p /var/run/dbus/
export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/var/run/dbus/system_bus_socket
sudo dbus-daemon --system --nofork &
sleep 2
xfce4-power-manager &
NetworkManager &

echo "starting pulseaudio ..."
# sudo pulseaudio --system --high-priority --no-cpu-limit -v -L 'module-alsa-sink device=plughw:0,1' >/dev/null 2>&1 &

sudo sed -i "s/^load-module module-console-kit/#load-module module-console-kit/g" /etc/pulse/default.pa #for: core-debian-9
sudo rm -rf /tmp/pulse-*
pulseaudio &
sleep 2; pavucontrol > /dev/null 2>&1 &
pactl load-module module-alsa-sink device=plughw:0,0

# wait forever not to exit the container
tail -f /dev/null #& wait ${!}
exit 0
