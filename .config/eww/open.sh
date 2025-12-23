#!/bin/bash
eww open $1 
hyprctl keyword bind ,escape,exec,"eww close $1 && hyprctl keyword unbind ,escape"

