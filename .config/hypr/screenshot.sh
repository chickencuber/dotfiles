#!/bin/bash

choice=$(echo -e "Active Monitor Screenshot\nActive Window Screenshot\nMonitor Screenshot\nWindow Screenshot\nRegion Screenshot" | wofi --dmenu --prompt "Choose:")
sleep 0.1

case "$choice" in
    "Active Window Screenshot") hyprshot -m active --mode window;;
    "Active Monitor Screenshot") hyprshot -m active --mode output;;
    "Monitor Screenshot") hyprshot -m output;;
    "Window Screenshot") hyprshot -m window ;;
    "Region Screenshot") hyprshot -m region ;;
    *) exit ;;
esac
