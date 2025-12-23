#!/bin/bash
ACTIVE_CLASS=$(hyprctl activewindow | grep -Po "class: \S+" | sed -n 's/^class: //p')
path="$HOME/.config/hypr/generated/$ACTIVE_CLASS.conf"
if [[ -f "$path" ]] then
    rm "$path"
else
    echo "windowrule = plugin:hyprbars:nobar, class:$ACTIVE_CLASS">>"$path"
fi
hyprctl reload


