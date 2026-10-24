#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [ "$#" -ne 0 ]; then
    printf 'Usage: %s\n' "$0" >&2
    exit 2
fi

if [ "$EUID" -eq 0 ]; then
    printf 'Run as your normal user, without sudo.\n' >&2
    exit 1
fi
if [ ! -r /etc/os-release ] || ! command -v gsettings >/dev/null 2>&1; then
    printf 'This installer requires Ubuntu and a running GNOME session.\n' >&2
    exit 1
fi
. /etc/os-release
distribution_id="${ID:-}"
if [ "$distribution_id" != ubuntu ]; then
    printf 'This installer currently supports Ubuntu only; detected %s (%s).\n' \
        "${PRETTY_NAME:-unknown}" "$distribution_id" >&2
    exit 1
fi
if ! command -v apt-get >/dev/null 2>&1; then
    printf 'Package manager apt-get was not found.\n' >&2
    exit 1
fi
shell_major="$(gnome-shell --version | grep -oE '[0-9]+' | head -n1)"
if [ -z "$shell_major" ] || [ "$shell_major" -lt 48 ]; then
    printf 'This installer requires GNOME Shell 48 or newer; detected %s.\n' "${shell_major:-unknown}" >&2
    exit 1
fi
for firefox_process in firefox firefox-bin; do
    if pgrep -u "$UID" -x "$firefox_process" >/dev/null 2>&1; then
        printf 'Force-closing Firefox before installing its profile theme...\n' >&2
        pkill -KILL -u "$UID" -x "$firefox_process" || true
    fi
done
sleep 1
for firefox_process in firefox firefox-bin; do
    if pgrep -u "$UID" -x "$firefox_process" >/dev/null 2>&1; then
        printf 'Could not stop Firefox; close it manually and run the installer again.\n' >&2
        exit 1
    fi
done

STATE_DIR="$HOME/.local/state/mactahoe-ubuntu"
mkdir -p "$STATE_DIR"
BACKUP_DIR=""
if [ -f "$STATE_DIR/latest-backup" ]; then
    previous_backup="$(cat "$STATE_DIR/latest-backup")"
    if [ -d "$previous_backup" ] && [ "$(dirname "$previous_backup")" = "$STATE_DIR" ]; then
        BACKUP_DIR="$previous_backup"
    fi
fi
if [ -z "$BACKUP_DIR" ]; then
    BACKUP_DIR="$(mktemp -d "$STATE_DIR/backup-$(date +%Y%m%d-%H%M%S)-XXXXXX")"
fi

package_list=(breeze-icon-theme conky-all dconf-cli fontconfig \
    gir1.2-adw-1 gir1.2-gtk-4.0 gnome-shell-extension-manager \
    gnome-shell-extension-user-theme gnome-tweaks imagemagick \
    libglib2.0-dev-bin librsvg2-bin python3-gi python3-pil sassc)
apt_snapshot="$BACKUP_DIR/apt-packages-before-mactahoe"
apt_installed="$BACKUP_DIR/apt-packages-installed-by-mactahoe"
if [ ! -e "$BACKUP_DIR/apt-tracking-version" ] && [ ! -e "$BACKUP_DIR/apt-tracking-legacy" ]; then
    if [ -e "$STATE_DIR/project-path" ]; then
        touch "$BACKUP_DIR/apt-tracking-legacy"
    else
        dpkg-query -W -f='${db:Status-Abbrev}\t${binary:Package}\n' \
            | awk '$1 ~ /^ii/ {print $2}' | LC_ALL=C sort -u > "$apt_snapshot"
    fi
fi
sudo apt-get update
sudo apt-get install -y "${package_list[@]}"
if [ -f "$apt_snapshot" ] && [ ! -e "$BACKUP_DIR/apt-tracking-version" ]; then
    dpkg-query -W -f='${db:Status-Abbrev}\t${binary:Package}\n' \
        | awk '$1 ~ /^ii/ {print $2}' | LC_ALL=C sort -u > "$BACKUP_DIR/apt-packages-after-mactahoe"
    awk 'NR==FNR {seen[$0]=1; next} !seen[$0]' "$apt_snapshot" "$BACKUP_DIR/apt-packages-after-mactahoe" > "$apt_installed"
    rm -f "$apt_snapshot" "$BACKUP_DIR/apt-packages-after-mactahoe"
    touch "$BACKUP_DIR/apt-tracking-version"
fi

mkdir -p "$HOME/.local/share/gnome-shell/extensions" \
    "$HOME/.local/share/fonts" "$HOME/.local/bin" "$HOME/.local/share/applications" \
    "$HOME/.local/share/mactahoe-widgets" "$HOME/.config/conky" \
    "$HOME/.config/mactahoe-widgets" "$HOME/.config/systemd/user" \
    "$HOME/.local/share/mactahoe-apps" \
    "$HOME/.local/share/icons/hicolor/scalable/apps" \
    "$HOME/Pictures/Wallpapers/MacTahoe"

if command -v dconf >/dev/null 2>&1 && [ ! -f "$BACKUP_DIR/dconf-before.ini" ]; then
    dconf dump / > "$BACKUP_DIR/dconf-before.ini" || true
fi
for path in gtk-3.0 gtk-4.0; do
    if [ ! -e "$BACKUP_DIR/captured/.config/$path" ]; then
        mkdir -p "$BACKUP_DIR/captured/.config"
        if [ -e "$HOME/.config/$path" ] && [ ! -e "$BACKUP_DIR/$path" ]; then
            cp -a "$HOME/.config/$path" "$BACKUP_DIR/"
        fi
        touch "$BACKUP_DIR/captured/.config/$path"
    fi
done
backup_item() {
    local relative="$1" backup_path="$BACKUP_DIR/home/$1" captured="$BACKUP_DIR/captured/home/$1"
    if [ ! -e "$captured" ]; then
        mkdir -p "$BACKUP_DIR/captured/home/$(dirname "$relative")"
        if { [ -e "$HOME/$relative" ] || [ -L "$HOME/$relative" ]; } && \
            [ ! -e "$backup_path" ] && [ ! -L "$backup_path" ]; then
            mkdir -p "$BACKUP_DIR/home/$(dirname "$relative")"
            cp -a "$HOME/$relative" "$backup_path"
        fi
        touch "$captured"
    fi
}
for relative in \
    .local/bin/mactahoe-widgets .local/bin/mactahoe-icon-manager \
    .local/bin/mactahoe-weather-fetch.py .local/bin/mactahoe-lunar-fetch.py \
    .local/bin/am-lich-viet-nam .local/bin/image-compressor \
    .local/bin/color-scheme-sync.sh .local/share/fonts/MacTahoe \
    .local/share/mactahoe-widgets .local/share/applications/mactahoe-widgets.desktop \
    .local/share/applications/mactahoe-icon-manager.desktop \
    .local/share/applications/vn.ihoan.AmLich.desktop \
    .local/share/applications/vn.ihoan.ImageCompressor.desktop \
    .local/share/mactahoe-apps/am-lich-viet-nam \
    .local/share/mactahoe-apps/image-compressor \
    .local/share/icons/hicolor/scalable/apps/vn.ihoan.AmLich.svg \
    .local/share/icons/hicolor/scalable/apps/vn.ihoan.ImageCompressor.svg \
    .config/mactahoe-widgets/weather.conf .config/mactahoe-widgets/settings.json \
    .config/systemd/user/color-scheme-sync.service \
    Pictures/Wallpapers/MacTahoe; do
    backup_item "$relative"
done
for file in "$HOME"/.config/conky/mactahoe-*; do
    [ ! -e "$file" ] || backup_item ".config/conky/${file##*/}"
done
if [ ! -e "$BACKUP_DIR/captured/theme-icons" ]; then
    mkdir -p "$BACKUP_DIR/captured"
    for path in "$HOME"/.themes/MacTahoe-* "$HOME"/.local/share/icons/MacTahoe*; do
        [ ! -e "$path" ] || backup_item "${path#"$HOME"/}"
    done
    touch "$BACKUP_DIR/captured/theme-icons"
fi
printf '%s\n' "$BACKUP_DIR" > "$STATE_DIR/latest-backup"
printf '%s\n' "$ROOT_DIR" > "$STATE_DIR/project-path"

mkdir -p "$HOME/.local/share/fonts/MacTahoe"
cp -a "$ROOT_DIR/assets/fonts/SF-Pro" "$ROOT_DIR/assets/fonts/SF-Mono" \
    "$HOME/.local/share/fonts/MacTahoe/"
fc-cache -f "$HOME/.local/share/fonts/MacTahoe"
(cd "$ROOT_DIR/vendor/MacTahoe-gtk-theme" && ./install.sh -l --shell -i apple -p default)
(cd "$ROOT_DIR/vendor/MacTahoe-icon-theme" && ./install.sh -t blue)
mkdir -p "$HOME/.local/share/icons/MacTahoe-cursors" "$HOME/.local/share/icons/MacTahoe-dark-cursors"
cp -a "$ROOT_DIR/vendor/MacTahoe-icon-theme/cursors/dist/." "$HOME/.local/share/icons/MacTahoe-cursors/"
cp -a "$ROOT_DIR/vendor/MacTahoe-icon-theme/cursors/dist-dark/." "$HOME/.local/share/icons/MacTahoe-dark-cursors/"
cp -a "$ROOT_DIR/assets/wallpapers/." "$HOME/Pictures/Wallpapers/MacTahoe/"

cp "$ROOT_DIR/apps/mactahoe-widgets" "$ROOT_DIR/apps/mactahoe-icon-manager" \
    "$ROOT_DIR/apps/mactahoe-weather-fetch.py" "$ROOT_DIR/apps/mactahoe-lunar-fetch.py" \
    "$ROOT_DIR/apps/color-scheme-sync.sh" "$HOME/.local/bin/"
cp "$ROOT_DIR/apps/launchers/am-lich-viet-nam" \
    "$ROOT_DIR/apps/launchers/image-compressor" "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin/mactahoe-widgets" "$HOME/.local/bin/mactahoe-icon-manager" \
    "$HOME/.local/bin/mactahoe-weather-fetch.py" "$HOME/.local/bin/mactahoe-lunar-fetch.py" \
    "$HOME/.local/bin/am-lich-viet-nam" "$HOME/.local/bin/image-compressor" \
    "$HOME/.local/bin/color-scheme-sync.sh"
cp "$ROOT_DIR/apps/lunar.py" "$HOME/.local/share/mactahoe-widgets/lunar.py"
mkdir -p "$HOME/.local/share/mactahoe-apps/am-lich-viet-nam" \
    "$HOME/.local/share/mactahoe-apps/image-compressor"
cp -a "$ROOT_DIR/apps/am-lich-viet-nam/." \
    "$HOME/.local/share/mactahoe-apps/am-lich-viet-nam/"
cp -a "$ROOT_DIR/apps/image-compressor/." \
    "$HOME/.local/share/mactahoe-apps/image-compressor/"
cp "$ROOT_DIR/apps/am-lich-viet-nam/assets/vn.ihoan.AmLich.svg" \
    "$HOME/.local/share/icons/hicolor/scalable/apps/"
cp "$ROOT_DIR/apps/image-compressor/assets/vn.ihoan.ImageCompressor.svg" \
    "$HOME/.local/share/icons/hicolor/scalable/apps/"

for conf in "$ROOT_DIR"/conky/mactahoe-*.conf; do
    sed "s|@HOME@|$HOME|g" "$conf" > "$HOME/.config/conky/${conf##*/}"
done
cp "$ROOT_DIR/conky/mactahoe-widgets.lua" "$HOME/.config/conky/"
sed "s|@HOME@|$HOME|g" "$ROOT_DIR/config/weather.conf" \
    > "$HOME/.config/mactahoe-widgets/weather.conf"

EXTENSION_IDS=(blur-my-shell@aunetx globalmenu@ShiroOSL.github.io \
    just-perfection-desktop@just-perfection)
COMPATIBLE_EXTENSION_IDS=()
INCOMPATIBLE_EXTENSION_IDS=()
for uuid in "${EXTENSION_IDS[@]}"; do
    if ! python3 -c 'import json, sys; data = json.load(open(sys.argv[1], encoding="utf-8")); sys.exit(0 if sys.argv[2] in data.get("shell-version", []) else 1)' \
        "$ROOT_DIR/vendor/gnome-extensions/$uuid/metadata.json" "$shell_major"; then
        printf 'Skipping %s: it does not declare support for GNOME Shell %s.\n' "$uuid" "$shell_major"
        INCOMPATIBLE_EXTENSION_IDS+=("$uuid")
        continue
    fi
    target="$HOME/.local/share/gnome-shell/extensions/$uuid"
    if [ ! -e "$BACKUP_DIR/captured/extensions/$uuid" ]; then
        mkdir -p "$BACKUP_DIR/captured/extensions"
        if [ -d "$target" ] && [ ! -e "$BACKUP_DIR/extensions/$uuid" ]; then
            mkdir -p "$BACKUP_DIR/extensions"
            cp -a "$target" "$BACKUP_DIR/extensions/"
        fi
        touch "$BACKUP_DIR/captured/extensions/$uuid"
    fi
    mkdir -p "${target%/*}"
    rm -rf "$target"
    cp -a "$ROOT_DIR/vendor/gnome-extensions/$uuid" "$target"
    if [ -d "$target/schemas" ]; then glib-compile-schemas "$target/schemas"; fi
    COMPATIBLE_EXTENSION_IDS+=("$uuid")
done

gs() {
    local schema="$1"; shift
    local command="$1"; shift
    local uuid schema_dir
    case "$schema" in
        org.gnome.shell.extensions.blur-my-shell*) uuid=blur-my-shell@aunetx ;;
        org.gnome.shell.extensions.globalmenu) uuid=globalmenu@ShiroOSL.github.io ;;
        org.gnome.shell.extensions.just-perfection) uuid=just-perfection-desktop@just-perfection ;;
        *) gsettings "$command" "$schema" "$@"; return $? ;;
    esac
    schema_dir="$HOME/.local/share/gnome-shell/extensions/$uuid/schemas"
    GSETTINGS_SCHEMA_DIR="$schema_dir" gsettings "$command" "$schema" "$@"
}

while read -r schema key value; do
    [ -n "${schema:-}" ] || continue
    if gs "$schema" writable "$key" >/dev/null 2>&1; then gs "$schema" set "$key" "$value"; fi
done < "$ROOT_DIR/config/gsettings.tsv"

wall="$HOME/Pictures/Wallpapers/MacTahoe/MacTahoe-night.jpeg"
wall_uri="$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).as_uri())' "$wall")"
gsettings set org.gnome.desktop.background picture-uri "$wall_uri"
gsettings set org.gnome.desktop.background picture-uri-dark "$wall_uri"
gsettings set org.gnome.desktop.background picture-options 'zoom'
gsettings set org.gnome.desktop.screensaver picture-uri "$wall_uri"
gsettings set org.gnome.desktop.screensaver picture-options 'zoom'

extension_ids=(user-theme@gnome-shell-extensions.gcampax.github.com)
for uuid in "${COMPATIBLE_EXTENSION_IDS[@]}"; do
    extension_ids+=("$uuid")
done
extension_ids+=(ubuntu-dock@ubuntu.com)
python3 - "${extension_ids[@]}" -- -- "${INCOMPATIBLE_EXTENSION_IDS[@]}" <<'PY'
import ast
import subprocess
import sys

schema = "org.gnome.shell"
key = "enabled-extensions"
raw_enabled = subprocess.check_output(["gsettings", "get", schema, key], text=True).strip()
enabled = ast.literal_eval(raw_enabled.removeprefix("@as "))
first_separator = sys.argv.index("--")
second_separator = sys.argv.index("--", first_separator + 1)
required = sys.argv[1:first_separator]
disabled = sys.argv[first_separator + 1:second_separator]
incompatible = sys.argv[second_separator + 1:]
enabled = [uuid for uuid in enabled if uuid not in disabled and uuid not in incompatible]
for uuid in required:
    if uuid not in enabled:
        enabled.append(uuid)
variant = "[" + ", ".join(repr(uuid) for uuid in enabled) + "]"
subprocess.run(["gsettings", "set", schema, key, variant], check=True)
PY

cp "$ROOT_DIR/desktop/mactahoe-widgets.desktop" "$HOME/.local/share/applications/"
cp "$ROOT_DIR/desktop/mactahoe-icon-manager.desktop" "$HOME/.local/share/applications/"
sed "s|^Exec=am-lich-viet-nam$|Exec=$HOME/.local/bin/am-lich-viet-nam|" \
    "$ROOT_DIR/desktop/vn.ihoan.AmLich.desktop" \
    > "$HOME/.local/share/applications/vn.ihoan.AmLich.desktop"
sed "s|^Exec=image-compressor$|Exec=$HOME/.local/bin/image-compressor|" \
    "$ROOT_DIR/desktop/vn.ihoan.ImageCompressor.desktop" \
    > "$HOME/.local/share/applications/vn.ihoan.ImageCompressor.desktop"
cp "$ROOT_DIR/systemd/color-scheme-sync.service" "$HOME/.config/systemd/user/"
systemctl --user daemon-reload
systemctl --user enable --now color-scheme-sync.service

for firefox_root in "$HOME/snap/firefox/common/.mozilla/firefox" "$HOME/.mozilla/firefox"; do
    [ -d "$firefox_root" ] || continue
    while IFS= read -r -d '' prefs; do
        profile="${prefs%/prefs.js}"
        chrome="$profile/chrome"
        if [ -d "$chrome" ] && [ ! -e "$profile/chrome.mactahoe-backup" ]; then
            cp -a "$chrome" "$profile/chrome.mactahoe-backup"
        fi
        mkdir -p "$chrome"
        cp -a "$ROOT_DIR/vendor/MacTahoe-gtk-theme/other/firefox/MacTahoe" "$chrome/"
        cp "$ROOT_DIR/vendor/MacTahoe-gtk-theme/other/firefox/customChrome.css" \
            "$ROOT_DIR/vendor/MacTahoe-gtk-theme/other/firefox/userChrome.css" \
            "$ROOT_DIR/vendor/MacTahoe-gtk-theme/other/firefox/userContent.css" "$chrome/"
        if [ -f "$profile/user.js" ]; then cp -n "$profile/user.js" "$profile/user.js.mactahoe-backup"; fi
        while IFS= read -r pref; do
            grep -Fqx "$pref" "$profile/user.js" || printf '%s\n' "$pref" >> "$profile/user.js"
        done < "$ROOT_DIR/config/firefox-user.js"
    done < <(find "$firefox_root" -mindepth 2 -maxdepth 4 -type f -name prefs.js -print0)
done

update-desktop-database "$HOME/.local/share/applications" || true
printf '\nInstalled. Log out and back in to load GNOME Shell extensions.\n'
printf 'Widgets start only when you click Widget MacTahoe.\nBackup: %s\n' "$BACKUP_DIR"
