#!/bin/bash
output="$HOME/Pictures/Screenshots/"
mkdir -p "$output"

if [[ "$1" == "normal" ]]; then
    hyprshot -m active --mode output -o "$output"
else
    qs -c rice ipc call screenshot toggle
fi
