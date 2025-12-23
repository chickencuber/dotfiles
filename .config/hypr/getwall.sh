#!/bin/bash
wall_dir="$HOME/.config/hypr/walls"
wallpapers=($(find "$wall_dir" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.gif" \) -printf "%f\n" | sort))
wallpapers+=("random")

function choose {
    if [ -f "$HOME/.config/hypr/wall" ]; then
        rm "$HOME/.config/hypr/wall"
    fi

    cp "$wall_dir/$1" "$HOME/.config/hypr/wall"
    yes | ffmpeg -i "$HOME/.config/hypr/wall" -vf "scale=200:-1" -vframes 1 "$HOME/.config/hypr/thumbnail.png" & 
    swww clear-cache
    swww img "$HOME/.config/hypr/wall" --transition-type fade --transition-duration 1
}

function choose_random {
    random_wall=$(basename "$(find "$wall_dir" -type f \( -iname "*.png" -o -iname "*gif" \) | shuf -n 1)")
    choose $random_wall   
}

if [[ "$1" == "random" ]]; then
    choose_random
elif [[ "$1" == "init" ]]; then #inits deamon
    while true; do
        sleep 300  
        if [ -e "$HOME/.config/hypr/wall_lock" ]; then
            choose_random
        fi
    done 
elif [[ "$1" == "toggle" ]]; then #toggles random wallpapers
    if [ -e "$HOME/.config/hypr/wall_lock" ]; then
        rm "$HOME/.config/hypr/wall_lock"
    else
        touch "$HOME/.config/hypr/wall_lock"
    fi
    pkill -RTMIN+10 waybar
elif [[ "$1" == "test" ]]; then
    if [ -e "$HOME/.config/hypr/wall_lock" ]; then
        echo '{"text": "slideshow", "class": "active-wall"}'
    else
        echo '{"text": "slideshow"}'
    fi
else

    choice=$(printf "%s\n" "${wallpapers[@]}" | wofi --dmenu --prompt "Select Wallpaper")

    if [[ "$choice" == "random" ]]; then
        choose_random
    elif [[ "$choice" != "" ]]; then
        choose $choice
    fi
fi
