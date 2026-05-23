#!/bin/bash
set -euo pipefail
git init
mkdir -p crates
cat > Cargo.toml << 'EOF'
[workspace]
resolver = "3"
members = [
    "crates/*"
]
EOF
echo "target/" >> .gitignore
