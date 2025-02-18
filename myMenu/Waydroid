waydroid session stop
notify-send "stoping waydroid"
sleep 10

pkill weston
notify-send "killinf weston"
sleep 10

notify-send "starting wayland"
systemctl start waydroid-container
sleep 10

notify-send "setting display"
weston --xwayland -i0&
export WAYLAND_DISPLAY=wayland-1
sleep 10
notify-send "waydroind full screen"
waydroid show-full-ui &
#sleep 30
#sudo mount --bind ~/Downloads ~/.local/share/waydroid/data/media/0/Download

#to exit
#waydroid session stop
# weston --xwayland --scale=2 & 
#
