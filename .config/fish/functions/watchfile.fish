function watchfile
    while true
        inotifywait -e modify "$argv[1]" 
        eval "$argv[2]"
    end
end
