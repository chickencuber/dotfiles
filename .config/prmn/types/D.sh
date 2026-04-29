#!/bin/bash
set -euo pipefail
echo 'import std.stdio;

void main() {
    writeln("Hello World");
}' > main.d
git init
