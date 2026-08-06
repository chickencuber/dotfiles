#!/bin/env fish


set a (eww get full-text)
set b (eww get autocomplete-suggestion)

set result "$a"(string sub -s (math (string length "$a") + 1) "$b")

eww update cmd-text=$result
ydotool key 107:1 107:0
