#!/bin/env fish
eww close command_run 
hyprctl keyword unbind ,escape 
hyprctl keyword unbind ,up 
hyprctl keyword unbind ,down
eww update autocomplete-suggestion=''
eww update cmd-history=0
eww update cmd-text=''
