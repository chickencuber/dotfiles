#!/bin/env fish
set in $argv[1]
set out (complete -C "$in" | head -n 1| cut -f1)
set len (string length $in)
set repeat (string repeat $len " ")

set args (string split ' ' $in)

set lenl (string length $args[-1])
set regex (string repeat $lenl ".")
if string match "$args[-1]*" $out;
    set out (string replace -r $regex "" $out)
end
set out "$repeat$out"

echo $out # for debugging
eww update autocomplete-suggestion="$out"


