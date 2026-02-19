#!/bin/bash
mkdir ./build
echo 'package main

import "core:fmt"

main :: proc() {
	fmt.println("Hello World!")
}' > main.odin

cat > justfile << 'EOF'
build:
    odin build main.odin -file -out:build/main
run:
    odin run main.odin -file
EOF
cat > .gitignore << 'EOF'
/build
EOF
git init
