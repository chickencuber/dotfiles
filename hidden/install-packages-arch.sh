#!/bin/bash
failed=()
w=$(wc -l< "./hidden/packagesarch.txt")
l=1
while IFS= read -r pkg; do
    echo "Installing $pkg [$l/$w]..."
    yay -S --needed "$pkg" --noconfirm </dev/tty || failed+=("$pkg")
    ((l++))
done < "./hidden/packagesarch.txt"
echo
if [ ${#failed[@]} -eq 0 ]; then
    echo "All packages installed successfully."
else
    echo "===== PACKAGES THAT NEED MANUAL INSTALL ====="
    for pkg in "${failed[@]}"; do
        echo "$pkg"
    done
fi

