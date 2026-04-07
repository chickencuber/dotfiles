#!/bin/bash
ACTIVE_CLASS=$(hyprctl activewindow | grep -Po "class: \S+" | sed -n 's/^class: //p')
path="$HOME/.config/hypr/generated/$ACTIVE_CLASS.conf"
if [[ -f "$path" ]] then
    rm "$path"
else
    echo "windowrule = hyprbars:no_bar true, match:class $ACTIVE_CLASS, match:float 1">>"$path"
fi
hyprctl reload


