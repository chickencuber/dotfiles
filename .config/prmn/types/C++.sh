#!/bin/bash
set -euo pipefail
mkdir -p src
mkdir -p include

# Main Cpp file
cat > src/main.cpp << 'EOF'
#include <print>
using std::println;

int main() {
    println("Hello world!");
    return 0;
}
EOF

# .gitignore
cat > .gitignore << 'EOF'
/build
/.cache
/compile_commands.json
EOF

#TASK(20260502-130606-630-n6-720): replace with CMAKE

name="$(basename "$PWD")"

# CMAKE
cat > CMakeLists.txt << EOF
cmake_minimum_required(VERSION 3.16)
project(${name} CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(${name}
    src/main.cpp
)

target_compile_definitions(${name} PRIVATE
    \$<\$<CONFIG:Debug>:DEBUG_BUILD=1>
)

target_include_directories(${name} PRIVATE 
    include
)
EOF

cat > justfile << EOF
build_dir := "build"
name :="${name}"

dev:
    cmake -S . -B {{build_dir}}/dev \
        -DCMAKE_BUILD_TYPE=Debug \
        -DENABLE_ASAN=ON \
        -DCMAKE_EXPORT_COMPILE_COMMANDS=1
    cmake --build {{build_dir}}/dev -j
    ln -sf build/dev/compile_commands.json compile_commands.json

# Run dev build
run-dev: dev
    {{build_dir}}/dev/{{name}}

run-gf2: dev
    gf2 {{build_dir}}/dev/{{name}}

release:
    cmake -S . -B {{build_dir}}/release \
        -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_ASAN=OFF
    cmake --build {{build_dir}}/release -j

run-release: release
    {{build_dir}}/release/{{name}}

clean:
    rm -rf {{build_dir}}
EOF

# .clang-format
cat > .clang-format << 'EOF'
---
BasedOnStyle: LLVM
IndentWidth: 4
PointerAlignment: Left
...
EOF

# Initialize git repo
git init
