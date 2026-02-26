#!/bin/bash
mkdir ./build
mkdir ./src
echo 'package main

import "core:fmt"

main :: proc() {
	fmt.println("Hello World!")
}' > src/main.odin

cat > justfile << 'EOF'
build:
    odin build src/main.odin -out:build/main
run:
    odin run src/main.odin -file
EOF
cat > .gitignore << 'EOF'
/build
EOF
git init
