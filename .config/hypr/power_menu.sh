#!/bin/bash
choice=$(echo "Reboot
Log Off
Shut Down
Lock" | wofi --dmenu --prompt "Power menu")

case "$choice" in
    "Reboot") reboot;;
    "Log Off") hyprctl dispatch exit;;
    "Shut Down") shutdown now;;
    "Lock") hyprlock;;
    *) exit ;;
esac
