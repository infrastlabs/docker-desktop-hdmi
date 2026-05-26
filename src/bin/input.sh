#!/bin/bash

# input.sh @entrypoint.sh
# add input devices and their events to X11 configuration
mkdir -p /etc/X11/xorg.conf.d/
conf=/etc/X11/xorg.conf.d/10-input.conf
rm -f $conf

# exit 0 #默认模式:会导致s11的键盘也不能用<容器tty2/tty7全不能用了..>
# create new input device file
cat > $conf <<_EOF_
Section "ServerFlags"
     #ff-hdmi-ref.exists
     Option "AutoAddDevices" "False"
     
     #禁止快捷键切屏(ctl+alt+fx)
     #Option "DontVTSwitch" "on"
     #强制焦点独占，失焦释放
     #Option "GrabDevice" "on"
     #防ctl+alt+backspace杀掉Xorg 
     #Option "DontZap" "on"
EndSection
_EOF_


# weipai-s11-touchMouse|dseek.ask|加后xorg不可启..
# cat >> $conf <<_EOF_
#     Section "InputClass"
#     Identifier "Event Mouse"
#     Driver "evdev"
#     Option "Device" "/dev/input/by-path/pci-0000:00:16.2-platform-i2c_designware.2-event-mouse"
# EndSection
# _EOF_
# 
# 260519 10:50|try2自动加载触摸板到容器=>加上无影响,但touchPad也不能用
cat >> $conf <<_EOF_
##try1:libinput######################
# ref dseek's: synaptics> libinput; 指定event7还是不行
# Section "InputClass"
#     Identifier "My Touchpad"
#     MatchIsTouchpad "on"
#     Driver "libinput"
#     #Option "NaturalScrolling" "on"
#     #Option "Tapping" "on"
#     Option "Device" "/dev/input/event7"
# EndSection

##try3:mice######################
# ref cat /_ext/xorg.conf.new-hostBunsen |grep -i mice -C 5 ##Xorg :2 -configure生成之
Section "InputDevice"
	Identifier  "Mouse0"
	Driver      "mouse"
	Option	    "Protocol" "auto"
  #mice/mouse0
	Option	    "Device" "/dev/input/mouse0"
	# Option	    "ZAxisMapping" "4 5 6 7"
EndSection

##try2:synaptics######################
# ref deb9-bunsen:/usr/share/X11/xorg.conf.d/70-synaptics.conf
#   ct-hdmi: xinput list; 还是无/apps.xf-mouse-settings也无
#   mv /usr/share/X11/xorg.conf.d/40-libinput.conf-bk
# Section "InputClass"
#         Identifier "touchpad catchall"
#         Driver "synaptics"
#         MatchIsTouchpad "on"
#         MatchDevicePath "/dev/input/event*"
# EndSection
# Section "InputClass"
#         Identifier "touchpad ignore duplicates"
#         MatchIsTouchpad "on"
#         MatchOS "Linux"
#         MatchDevicePath "/dev/input/mouse*"
#         Option "Ignore" "on"
# EndSection

# This option is only interpreted by clickpads.
# Section "InputClass"
#         Identifier "Default clickpad buttons"
#         MatchDriver "synaptics"
#         Option "SoftButtonAreas" "50% 0 82% 0 0 0 0 0"
#         Option "SecondarySoftButtonAreas" "58% 0 0 15% 42% 58% 0 15%"
# EndSection
# This option disables software buttons on Apple touchpads. # This option is only interpreted by clickpads.
# Section "InputClass"
#         Identifier "Disable clickpad buttons on Apple touchpads"
#         MatchProduct "Apple|bcm5974"
#         MatchDriver "synaptics"
#         Option "SoftButtonAreas" "0 0 0 0 0 0 0 0"
# EndSection
_EOF_

cd /dev/input
#for input in event* do
# 当前启动后event7为touchPad, 上一段落打开时, 本处如再使用event7:会导致键鼠全卡死(即使新启时stopped lightdm)
ls event* |grep -v event7 |while read input; do
cat >> $conf <<_EOF_
    Section "InputDevice"
    Identifier "$input"
    Option "Device" "/dev/input/$input"
    Option "AutoServerLayout" "true"
    Driver "evdev"
EndSection
_EOF_
done

# $ cat /proc/bus/input/devices   |egrep "Name|Handler"
# N: Name="AT Translated Set 2 keyboard"
# H: Handlers=sysrq kbd leds event0 
  # N: Name="Intel HID events"
  # H: Handlers=kbd event1 rfkill 
  # N: Name="Lid Switch"
  # H: Handlers=event2 
  # N: Name="Power Button"
  # H: Handlers=kbd event3 
  # N: Name="Video Bus"
  # H: Handlers=kbd event4 
  # N: Name="PC Speaker"
  # H: Handlers=kbd event5 
  # N: Name="USB 2.0 Camera"
  # H: Handlers=kbd event6 
# N: Name="SYNA3602:00 0911:5288 Touchpad"
# H: Handlers=mouse0 event7 
# # N: Name="HDA Intel PCH Mic"
# # H: Handlers=event8 
# # N: Name="HDA Intel PCH Headphone"
# # H: Handlers=event9 
# # N: Name="HDA Intel PCH HDMI/DP,pcm=3"
# # H: Handlers=event10 
# # N: Name="HDA Intel PCH HDMI/DP,pcm=7"
# # H: Handlers=event11 
# # N: Name="HDA Intel PCH HDMI/DP,pcm=8"
# # H: Handlers=event12
test -d /usr/share/X11/xorg.conf.d && mv /usr/share/X11/xorg.conf.d /usr/share/X11/xorg.conf.d-bk
cat > $conf <<_EOF_
Section "ServerFlags"
    # 设置false, event7:InputDevice.Driver=synaptics才有效(注释之:即使上2条mv了,也导致InputDevice不能注册上event7)
    Option "AutoAddDevices" "False"
EndSection
Section "InputDevice"
    Identifier "kb event0"
    Option "Device" "/dev/input/event0"
    Option "AutoServerLayout" "true"
    Driver "evdev"
EndSection

##00-keyboard.conf #dseek.for_xfce4_session=>none.effect || setxkbmap@opbox/autostart
# Section "InputClass"
#     Identifier "Keyboard Defaults"
#     MatchIsKeyboard "on"
#     Option "XkbRules" "evdev"
#     Option "XkbModel" "pc105"
#     Option "XkbLayout" "us"
# EndSection

#################################
# 260520 11:40|ref deb9-bunsen//usr/share/X11/xorg.conf.d/; event0/event7单独调试=>touchOK
#   0.tty7-lightdm-bunsen桌面: 不用停,event0/7可在两边切换;
#   1.event7挂上后deb9.pulseaudio异常: dbus org.pulsAudio1占用??
#   2.deb9.tty9停=>ubt22.tty8启: libinput/evdev/synaptics全不行了.. [ubt22不行:因未更新image,不带xserver-xorg-input-synaptics驱动]
#   3.12:50=>#  Option "AutoAddDevices" "False" ##注释之,免影响InputClass的动态加载(dseek: 设False则InputClass匹配规则失效)
#   4.14:50=> AutoAddDevices=False, InputDevice+synaptics: [ubt20/22/24]可以用touch板了! (前者为新pull, 后两者需pull更新image)
#   5.tty8.ubt/tty9.deb9多跑: pulghw:0,0声卡被deb9抢占,需停之再重启ubt容器即可
#################################
# deb9: InputDevice.ok; InputClass.bad
# Section "InputClass"
Section "InputDevice"
        Identifier "touch event7-12"
        # MatchIsTablet "on"
        # MatchDevicePath "/dev/input/event7"
        Option "Device" "/dev/input/event7"
        # TODO: udev未挂到容器内.
        # Option "Device" "/dev/input/by-path/pci-0000:00:16.2-platform-i2c_designware.2-event-mouse"
        # 
        # deb9: libinput/evdev:bad; synaptics:ok
        # ubt22:libinput/evdev:bad; synaptics:bad [InputDevice,InputClass全一样]=>驱动?
        # Driver "libinput"
        # Driver "evdev"
        Driver "synaptics"
        # for左右按键(不带:则只能移动/单点选择); ubt22:无时可左双击/无右键
        Option "SoftButtonAreas" "50% 0 82% 0 0 0 0 0"
        Option "SecondarySoftButtonAreas" "58% 0 0 15% 42% 58% 0 15%"
EndSection

# copy2 test: deb9-还是无效
# Section "InputClass"
#         Identifier "libinput pointer catchall"
#         # MatchIsPointer "on"
#         # MatchIsTouchpad "on"
#         MatchDevicePath "/dev/input/event7"
#         # Driver "libinput"
#         Driver "evdev"
#         # Driver "synaptics"
# EndSection


# 260529:weipai-s11--intel.i915(xserver-xorg-video-intel, all内不含)==>TODO.xorg不配置时,可自动匹配?
#==10-amdgpu.conf
# Section "OutputClass"
# 	Identifier "AMDgpu"
# 	MatchDriver "amdgpu"
# 	Driver "amdgpu"
# EndSection

# sam @ debian in /usr/share/X11/xorg.conf.d |10:54:24  
# $ ls /usr/share/X11/xorg.conf.d/* |while read one; do echo -e "\n#==$one"; cat /usr/share/X11/xorg.conf.d/$one |egrep -v "^#|^$" ; done
#==10-amdgpu.conf
# Section "OutputClass"
# 	Identifier "AMDgpu"
# 	MatchDriver "amdgpu"
# 	Driver "amdgpu"
# EndSection

#==10-evdev.conf
# Section "InputClass"
#         Identifier "evdev pointer catchall"
#         MatchIsPointer "on"
#         MatchDevicePath "/dev/input/event*"
#         Driver "evdev"
# EndSection
# Section "InputClass"
#         Identifier "evdev keyboard catchall"
#         MatchIsKeyboard "on"
#         MatchDevicePath "/dev/input/event*"
#         Driver "evdev"
# EndSection
# Section "InputClass"
#         Identifier "evdev touchpad catchall"
#         MatchIsTouchpad "on"
#         MatchDevicePath "/dev/input/event*"
#         Driver "evdev"
# EndSection
# Section "InputClass"
#         Identifier "evdev tablet catchall"
#         MatchIsTablet "on"
#         MatchDevicePath "/dev/input/event*"
#         Driver "evdev"
# EndSection
# Section "InputClass"
#         Identifier "evdev touchscreen catchall"
#         MatchIsTouchscreen "on"
#         MatchDevicePath "/dev/input/event*"
#         Driver "evdev"
# EndSection

#==10-quirks.conf
# Section "InputClass"
#         Identifier "ThinkPad HDAPS accelerometer blacklist"
#         MatchProduct "ThinkPad HDAPS accelerometer data"
#         Option "Ignore" "on"
# EndSection
# Section "InputClass"
#         Identifier "Xen Virtual Pointer axis blacklist"
#         MatchProduct "Xen Virtual Pointer"
#         Option "IgnoreAbsoluteAxes" "off"
#         Option "IgnoreRelativeAxes" "off"
# EndSection
# Section "InputClass"
#         Identifier "Tag trackballs as XI_TRACKBALL"
#         MatchProduct "trackball"
#         MatchDriver "evdev"
#         Option "TypeName" "TRACKBALL"
# EndSection
# Section "InputClass"
#         Identifier "Tag Mionix Naos 5000 mouse XI_MOUSE"
#         MatchProduct "La-VIEW Technology Naos 5000 Mouse"
#         MatchDriver "evdev"
#         Option "TypeName" "MOUSE"
# EndSection

#==40-libinput.conf
# Section "InputClass"
#         Identifier "libinput pointer catchall"
#         MatchIsPointer "on"
#         MatchDevicePath "/dev/input/event*"
#         Driver "libinput"
# EndSection
# Section "InputClass"
#         Identifier "libinput keyboard catchall"
#         MatchIsKeyboard "on"
#         MatchDevicePath "/dev/input/event*"
#         Driver "libinput"
# EndSection
# Section "InputClass"
#         Identifier "libinput touchpad catchall"
#         MatchIsTouchpad "on"
#         MatchDevicePath "/dev/input/event*"
#         Driver "libinput"
# EndSection
# Section "InputClass"
#         Identifier "libinput touchscreen catchall"
#         MatchIsTouchscreen "on"
#         MatchDevicePath "/dev/input/event*"
#         Driver "libinput"
# EndSection
# Section "InputClass"
#         Identifier "libinput tablet catchall"
#         MatchIsTablet "on"
#         MatchDevicePath "/dev/input/event*"
#         Driver "libinput"
# EndSection

#==70-synaptics.conf
# Section "InputClass"
#         Identifier "touchpad catchall"
#         Driver "synaptics"
#         MatchIsTouchpad "on"
# EndSection
# Section "InputClass"
#         Identifier "touchpad ignore duplicates"
#         MatchIsTouchpad "on"
#         MatchOS "Linux"
#         MatchDevicePath "/dev/input/mouse*"
#         Option "Ignore" "on"
# EndSection
# Section "InputClass"
#         Identifier "Default clickpad buttons"
#         MatchDriver "synaptics"
#         Option "SoftButtonAreas" "50% 0 82% 0 0 0 0 0"
#         Option "SecondarySoftButtonAreas" "58% 0 0 15% 42% 58% 0 15%"
# EndSection
# Section "InputClass"
#         Identifier "Disable clickpad buttons on Apple touchpads"
#         MatchProduct "Apple|bcm5974"
#         MatchDriver "synaptics"
#         Option "SoftButtonAreas" "0 0 0 0 0 0 0 0"
# EndSection

#==70-wacom.conf
# ...
_EOF_

echo cat $conf
cat $conf
