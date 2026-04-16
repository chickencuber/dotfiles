#!/bin/env fish
if test $argv[1] = "up"
    eww update cmd-history=(math (eww get cmd-history) + 1)
else if test $argv[1] = "down"
    eww update cmd-history=(math (eww get cmd-history) - 1)
end

set History (eww get cmd-history)
if test $History = 0
    eww update cmd-text=""
else if test $History -lt 0
    eww update cmd-history=0
else
    eww update cmd-text=(history | sed -n "$(eww get cmd-history)p")
end

