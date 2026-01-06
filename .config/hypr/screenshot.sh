#!/bin/bash
output="$HOME/Pictures/Screenshots/"
mkdir -p "$output"

if [[ "$1" == "normal" ]]; then
    hyprshot -m active --mode output -o "$output"
else
    choice=$(echo -e "Active Monitor Screenshot\nActive Window Screenshot\nMonitor Screenshot\nWindow Screenshot\nRegion Screenshot" | wofi --dmenu --prompt "Choose:")
    sleep 0.1
    case "$choice" in
        "Active Window Screenshot") hyprshot -m active --mode window -o "$output";;
        "Active Monitor Screenshot") hyprshot -m active --mode output -o "$output";;
        "Monitor Screenshot") hyprshot -m output -o "$output";;
        "Window Screenshot") hyprshot -m window -o "$output";;
        "Region Screenshot") hyprshot -m region -o "$output";;
        *) exit ;;
    esac
fi
