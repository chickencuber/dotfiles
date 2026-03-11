#!/bin/bash
mkdir ./build
mkdir ./src
echo 'package main

import "core:fmt"

main :: proc() {
	fmt.println("Hello World!")
}' > src/main.odin

cat > justfile << 'EOF'
out:="build/main"

build flag="":
    odin build src -out:{{out}} {{flag}} 

run arg="":
    just build
    {{out}} {{arg}}

run-debug-gf2 arg="":
    just build -debug
    gf2 --args {{out}} {{arg}}
    
run-debug arg="":
    just build -debug
    {{out}} {{arg}}
EOF
cat > .gitignore << 'EOF'
/build
EOF
git init
