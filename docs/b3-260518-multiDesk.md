

### 260518 11:20|weipai-s11-deb9调试多tty启动(deb9-bunsen桌面在tty7已跑:Xorg-0)

- ref deb9.ali-mirror `http://mirrors.aliyun.com/debian-archive/debian`
  - fk-jackyzy823-fxa-selfhosting//single/entry.sh
  - docker-x11base//distros/src/oth/Dockerfile.apt-debian
  - quickstart-actions//data/press-builder/Dockerfile.deb9
  - dotfiles//docs/250920-perl-asbru.md
- sys-vers
  - debian7-kx-xorg1.12
  - debian8-kx-xorg1.16
  - debian9-k4.9-xorg1.19(7.7) `touchPad:inputDevice.synaptics`
  - ubuntu20-k5.4-xorg1.20(7.7) `touchPad:inputDevice.synaptics[ubt20/22/24]`
- sys-glibc https://distrowatch.com/table.php?distribution=ubuntu #ubuntu/debian
  - ubt26-2.43|ubt24-2.39|ubt22-2.35|ubt20-2.31|ubt18-2.27|ubt16-2.23|ubt14-2.19|`ubt12-2.15|ubt10-2.11@2010|ubt8-2.7|ubt6-2.3@2006`
  - deb13-2.41|deb12-2.36|deb11-2.31|deb10-2.28|deb9-2.24|deb8-2.19@2015|deb7-2.13@2013`|deb6-2.11@2011|deb5-2.7@2009|deb4-2.3@2007|deb3-2.2@2002|deb2-2.0@1998`

```bash
# insDocker.sh升级Docker: deb9-apt-docker-ce17.12不能下载到docker-hdmi-desktop相关tag镜像, 升级docker-20.10.24后可以
# entry.sh并行桌面在tty2启动: sudo Xorg :1 &; export DISPLAY=:1
  1.vid: 可在tty2启动，图像加载正常,键盘可用,触摸板暂不能用; (mice/mouse0未加载到input?)
  2.aud: pulse-control能显示"HDA intel PCH"设备, 但play ~/3476.mp3无音(deb9-bunsen桌面是可以的; 容器内aplay-L可识别设备)

# 12:00调试touchMouse
  1.input.sh顶部直接exit0不做conf指定:# exit 0 #默认模式:会导致s11的键盘也不能用<容器tty2/tty7全不能用了..>
  2.强制重启后,stop lightdm; dcp start; #修正input.sh-exit0再退lightdm, dcp-start也卡死?
  3.再启试:stop lightdm; ct容器开始在跑/但xorg未启成功; 
     手动进入启Xorg-:1及startxfce4/openbox-session:前者也不能用鼠标/后者headless下跑的:无显?; 
     再kill/start容器; 可进到openbox-session环境:键盘可用/touch鼠标不行(tty4显示了,不在tty2)
  4.touchMouse不兼容ubt24-Xorg?(有一堆特性提示kernel需>4.16); DO:换usb鼠标尝试=>晚上:usb鼠标可用

# 14:50-15:35-16:15|xorg-try2 键鼠切换控制
  0.指定tty: #Xorg :1 vt8
  1.novtswitch/DontVTSwitch不能设定,导致ctl+alt+fx不可切换
  #entry.sh|#sudo Xorg :1 vt8 -novtswitch &
  #input.sh|#Option "DontVTSwitch" "on"
  #宿主机xorg-lightdm有设定novtswitch(仍可切换,why?)|/usr/lib/xorg/Xorg :0 -seat seat0 -auth /var/run/lightdm/root/:0 -nolisten tcp vt7 -novtswitch
  3.hdmi-desk.TODO: chvt@kbd / nmcli@network-manager的安装

# 260519 10:00|docker-hdmi-desktop:core-debian-8尝试(昨晚编译)=> Xorg :1启动err(no screen found)
# 260519 10:20|play ~/3*.mp3音频播放OK; 
   12  2026-05-19 10:15:31 pactl unload-module module-alsa-sink #plughw:0,3做卸载(/entry.sh尾部默认自动加载之:对应HDMI的默认输出口[card0,device3])
   13  2026-05-19 10:15:35 pactl load-module module-alsa-sink device=plughw:0,0 #非HDMI,指定第一个即可(重启后不做lightdm登录,免设备被bunsen桌面占用)
  # 11:20|lightdm-session命令行退出
  # loginctl
    loginctl list-sessions
    loginctl terminate-session xx; #bunsen桌面-headless下跑Xorg导致替显黑屏?: c1-lightdm杀后还未释放, 2号也kill才恢复到lightdm-login页; 4号:tty5控制台;
  # dm-tool
    dm-tool switch-to-greeter #需在X环境下执行

# oth1: tty8/9容器xorg多跑后, tty7-lightdm休眠锁定卡lock图标=>电源管理免休眠锁定即可(0519-dseek查资料时有提及)
#################################
# 260520 11:40|ref deb9-bunsen//usr/share/X11/xorg.conf.d/; event0/event7单独调试=>touchOK
#   0.tty7-lightdm-bunsen桌面: 不用停,event0/7可在两边切换;
#   1.event7挂上后deb9.pulseaudio异常: dbus org.pulsAudio1占用??
#   2.deb9.tty9停=>ubt22.tty8启: libinput/evdev/synaptics全不行了.. [ubt22不行:因未更新image,不带xserver-xorg-input-synaptics驱动] (0521shangwu:deb12-touch可用)
#   3.12:50=>#  Option "AutoAddDevices" "False" ##注释之,免影响InputClass的动态加载(dseek: 设False则InputClass匹配规则失效)
#   4.14:50=> AutoAddDevices=False, InputDevice+synaptics: [ubt20/22/24]可以用touch板了! (前者为新pull, 后两者需pull更新image)
#   5.tty8.ubt/tty9.deb9多跑: pulghw:0,0声卡被deb9抢占,需停之再重启ubt容器即可


# TODO
  1.容器内基于lightdm做桌面加载
  2.xfce4-power-manager|容器内电源管理(0519-try1:启动无tray图标)
  3.network-manager|网络连接<cur:deb9-bunsen桌面控制的wifi连接; TODO:配置写死/nmcli操作>(network-manager安装,同上1条:都依赖dbus) `/entry.sh add: dbus-daemon --system --nofork &`

```

