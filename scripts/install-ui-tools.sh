#!/usr/bin/env bash
set -euo pipefail

if ! command -v apt-get >/dev/null 2>&1; then
    printf 'This installer requires Ubuntu or another apt-based system.\n' >&2
    exit 1
fi

sudo apt-get update
sudo apt-get install -y gnome-tweaks gnome-shell-extension-manager
