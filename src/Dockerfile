#use armv7hf compatible base image
# https://github.com/HilscherAutomation/netPI-desktop-hdmi/blob/master/Dockerfile
# FROM balenalib/armv7hf-debian:buster-20191223
# https://github.com/MarcelCoding/docker-desktop-hdmi/blob/main/Dockerfile
# FROM balenalib/aarch64-debian:buster
# https://gitee.com/infrastlabs/docker-hdmi-desktop/blob/sam-custom/src/Dockerfile
# FROM balenalib/amd64-debian:buster ##multi-arch:fail
# FROM balenalib/debian:buster ##not existed
# FROM debian:buster ##9 80.03 Please select the layout matching the keyboard for this machine.
# FROM balenalib/amd64-debian:buster

# buildx.preTrans:
ARG TARGETARCH
# FROM balenalib/debian:buster-${TARGETARCH}
FROM hkccr.ccs.tencentyun.com/infrasync/v2025:balenalib--debian---buster-${TARGETARCH}

#dynamic build arguments coming from the /hooks/build file
ARG BUILD_DATE
ARG VCS_REF

#metadata labels
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/infrastlabs/docker-hdmi-desktop" \
      org.label-schema.vcs-ref=$VCS_REF

#version
ENV HILSCHERNETPI_DESKTOP_HDMI_VERSION 1.5.0

#labeling
LABEL maintainer="sldevsir@126.com" \ 
      version=$HILSCHERNETPI_DESKTOP_HDMI_VERSION \
      description="Desktop"

#set user credentials
ENV USER=testuser
ENV PASSWD=mypassword

#update source lists, keys
#create testuser
# adduser: The group `input' does not exist.
RUN apt-get update \
 && useradd --create-home --shell /bin/bash $USER \
 && echo $USER:$PASSWD | chpasswd \
 && adduser $USER tty \
 && adduser $USER video \
 && adduser $USER sudo \
 && addgroup input; adduser $USER input \
 && mkdir -p /etc/sudoers.d; echo $USER " ALL=(root) NOPASSWD:ALL" >> /etc/sudoers.d/$USER \
 && chmod 0440 /etc/sudoers.d/$USER \
 && apt install -yq \
#install ssh
    openssh-server \
 && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
 && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd \
 && mkdir /var/run/sshd \
#install xserver, desktop, login manager, ALSA sound driver
 && apt install -yq \
    xserver-xorg \
    xinit \
    xfce4 \
    xfce4-terminal \
 && mkdir /etc/X11/xorg.conf.d \
 && chmod u+s /usr/bin/Xorg \
 && chown -c $USER /etc/X11/xorg.conf.d \
 && apt install -yq \
    xserver-xorg-input-evdev \
    gnome-icon-theme tango-icon-theme \
    alsa-oss alsa-tools alsa-tools-gui alsa-utils alsamixergui mpg123 \
# && touch /home/$USER/.Xauthority \
# && chmod 777 /home/$USER/.Xauthority \
 && rm -rf /var/lib/apt/lists/*

#install userland raspberry pi tools (needed vor VNC)
RUN apt-get update && apt install -yq \
    git \
#  && git clone --depth 1 https://github.com/raspberrypi/firmware /tmp/firmware \
#  #11.98 mv: cannot stat '/tmp/firmware/hardfp/opt/vc': No such file or directory
#  && mv /tmp/firmware/hardfp/opt/vc /opt \
#  && echo "/opt/vc/lib" >/etc/ld.so.conf.d/00-vmcs.conf \
#  && /sbin/ldconfig \
#  && rm -rf /opt/vc/src \
#  
#  && echo "deb http://archive.raspberrypi.org/debian/ buster main" | tee -a /etc/apt/sources.list \
#  && gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-key 82B129927FA3303E \
#  && gpg -a --export 82B129927FA3303E | apt-key add - \
 && apt update \
 && apt install -yq \
# #install VNC
# # 5.793 E: Unable to locate package realvnc-vnc-server
#     realvnc-vnc-server \
#install pulseaudio
    dbus-x11 pulseaudio \
 && sed -i -e 's;load-module module-console-kit;#load-module module-console-kit;' /etc/pulse/default.pa \
 && usermod -a -G audio $USER \
 && usermod -a -G pulse $USER \
 && usermod -a -G pulse-access $USER \
#  && apt install \
# #install chromium browser
#     chromium-browser \
# #install screensaver
#     xscreensaver \
#install anydesk
 && apt install -yq \
    wget \
#  && wget https://download.anydesk.com/rpi/anydesk_5.1.1-1_armhf.deb -P /tmp/ \
#  && dpkg -i /tmp/anydesk_5.1.1-1_armhf.deb || apt install -f \
 && apt install libgles2* \
 && rm -rf /tmp/* \
#  && apt remove wget git \
 && apt autoremove \
 && apt upgrade \
 && rm -rf /var/lib/apt/lists/*

# AUDIO
RUN \
  sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list; \
  echo 'apt update -qq && apt install -yq --no-install-recommends $@ && apt clean && rm -rf /var/lib/apt/lists/*; ' > /usr/local/bin/apt.sh \
    && chmod +x /usr/local/bin/apt.sh; \
  # \2487 kB
  apt.sh wget ca-certificates \
  # \5529 kB 
  curl lame sox libsox-fmt-mp3 \
  # \4610 kB
  htop rsync tree tmux lrzsz psmisc fuse net-tools iputils-ping \
  procps sudo iproute2 iptables zip unzip xz-utils vim-tiny 
RUN \
# lame sox libsox-fmt-mp3
  apt.sh pavucontrol beep; \
  echo "curl mp3.." && su - testuser -c "curl --connect-timeout 3 -k -O -fSL https://downsc.chinaz.net/files/download/sound1/201309/3476.mp3";


# feichengwurao
# https://downsc.chinaz.net/files/download/sound1/201309/3476.mp3
# play 3476.mp3

#   # bash-static
#   # https://github.com/robxu9/bash-static/releases/download/5.2.015-1.2.3-2/bash-linux-x86_64
#   case ${TARGETPLATFORM} in \
#     "linux/amd64")  arch=x86_64    ;; \
#     "linux/arm64")  arch=aarch64  ;; \
#     "linux/arm/v7") arch=armv7    ;; \
#     "linux/arm/v6") arch=armv6  ;; \
#     "linux/386")    arch=i386     ;; \
#   esac; \
#   dst=$third/bin/bash; \
#   curl -o $dst -k -fSL https://github.com/robxu9/bash-static/releases/download/5.2.015-1.2.3-2/bash-linux-$arch; chmod +x $dst; \
  

#copy files
# COPY "./init.d/*" /etc/init.d/
COPY src/entrypoint.sh /

#set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]

#SSH port
EXPOSE 22

#set STOPSGINAL
STOPSIGNAL SIGTERM

#start container as non-root user, else chromium will not run
USER $USER
