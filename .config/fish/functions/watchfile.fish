function watchfile
    set file "$argv[1]"
    set cmd "$argv[2]"
    while true
        inotifywait -e modify "$file" 
        eval (string replace '¢file' $file $cmd)
    end
end
