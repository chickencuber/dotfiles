#!/bin/bash
ACTIVE_CLASS=$(hyprctl activewindow | grep -Po "class: \S+" | sed -n 's/^class: //p')
path="$HOME/.config/hypr/generated/$ACTIVE_CLASS.lua"
if [[ -f "$path" ]] then
    rm "$path"
else
    echo "hl.window_rule({match = {class= '$ACTIVE_CLASS',float=true},['hyprbars:no_bar'] = true,})">>"$path"
fi
hyprctl reload


