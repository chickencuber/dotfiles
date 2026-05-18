#!/bin/env fish
eww close command_run 
hyprctl eval 'hl.unbind("ESCAPE")'
hyprctl eval 'hl.unbind("UP")'
hyprctl eval 'hl.unbind("DOWN")'
eww update autocomplete-suggestion=''
eww update cmd-history=0
eww update cmd-text=''
