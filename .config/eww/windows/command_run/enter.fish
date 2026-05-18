#!/bin/env fish
hyprctl eval 'hl.bind("ESCAPE", hl.dsp.exec_cmd("~/.config/eww/windows/command_run/exit.fish"))'
hyprctl eval 'hl.bind("UP", hl.dsp.exec_cmd("~/.config/eww/windows/command_run/set_history.fish up"))'
hyprctl eval 'hl.bind("DOWN", hl.dsp.exec_cmd("~/.config/eww/windows/command_run/set_history.fish down"))'
