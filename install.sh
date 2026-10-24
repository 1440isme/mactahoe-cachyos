#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_GDM=1
case "${1:-}" in
    "") ;;
    --without-gdm) INSTALL_GDM=0 ;;
    *) printf 'Usage: %s [--without-gdm]\n' "$0" >&2; exit 2 ;;
esac

if [ "$EUID" -eq 0 ]; then
    printf 'Run as your normal user, without sudo.\n' >&2
    exit 1
fi
if [ ! -r /etc/os-release ] || ! command -v gsettings >/dev/null 2>&1; then
    printf 'This installer requires a supported Linux distribution and a running GNOME session.\n' >&2
    exit 1
fi
. /etc/os-release
distribution_id="${ID:-}"
distribution_like=" ${ID_LIKE:-} "
case "$distribution_id" in
    ubuntu|debian) package_manager=apt-get ;;
    fedora) package_manager=dnf ;;
    arch) package_manager=pacman ;;
    *)
        case "$distribution_like" in
            *" debian "*|*" ubuntu "*) package_manager=apt-get ;;
            *" fedora "*|*" rhel "*) package_manager=dnf ;;
            *" arch "*) package_manager=pacman ;;
            *) printf 'Unsupported distribution: %s (%s).\n' "${PRETTY_NAME:-unknown}" "$distribution_id" >&2; exit 1 ;;
        esac
        ;;
esac
if ! command -v "$package_manager" >/dev/null 2>&1; then
    printf 'Package manager %s was not found.\n' "$package_manager" >&2
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
BACKUP_DIR="$STATE_DIR/backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR" "$HOME/.local/share/gnome-shell/extensions" \
    "$HOME/.local/share/fonts" "$HOME/.local/bin" "$HOME/.local/share/applications" \
    "$HOME/.local/share/mactahoe-widgets" "$HOME/.config/conky" \
    "$HOME/.config/mactahoe-widgets" "$HOME/.config/systemd/user" \
    "$HOME/Pictures/Wallpapers/MacTahoe"

if command -v dconf >/dev/null 2>&1; then dconf dump / > "$BACKUP_DIR/dconf-before.ini" || true; fi
for path in gtk-3.0 gtk-4.0; do
    [ ! -e "$HOME/.config/$path" ] || cp -a "$HOME/.config/$path" "$BACKUP_DIR/"
done
backup_item() {
    local relative="$1"
    if [ -e "$HOME/$relative" ] || [ -L "$HOME/$relative" ]; then
        mkdir -p "$BACKUP_DIR/home/$(dirname "$relative")"
        cp -a "$HOME/$relative" "$BACKUP_DIR/home/$relative"
    fi
}
for relative in \
    .local/bin/mactahoe-widgets .local/bin/mactahoe-icon-manager \
    .local/bin/mactahoe-weather-fetch.py .local/bin/mactahoe-lunar-fetch.py \
    .local/bin/color-scheme-sync.sh .local/share/fonts/MacTahoe \
    .local/share/mactahoe-widgets .local/share/applications/mactahoe-widgets.desktop \
    .local/share/applications/mactahoe-icon-manager.desktop \
    .config/mactahoe-widgets/weather.conf .config/systemd/user/color-scheme-sync.service \
    Pictures/Wallpapers/MacTahoe; do
    backup_item "$relative"
done
for file in "$HOME"/.config/conky/mactahoe-*; do
    [ ! -e "$file" ] || backup_item ".config/conky/${file##*/}"
done
for path in "$HOME"/.themes/MacTahoe-* "$HOME"/.local/share/icons/MacTahoe*; do
    [ ! -e "$path" ] || backup_item "${path#"$HOME"/}"
done
printf '%s\n' "$BACKUP_DIR" > "$STATE_DIR/latest-backup"
printf '%s\n' "$ROOT_DIR" > "$STATE_DIR/project-path"

case "$package_manager" in
    apt-get)
        package_list=(breeze-icon-theme conky-all dconf-cli fontconfig \
            gir1.2-adw-1 gir1.2-gtk-4.0 gnome-shell-extension-manager \
            gnome-shell-extension-user-theme gnome-tweaks imagemagick \
            libglib2.0-dev-bin librsvg2-bin python3-gi sassc)
        sudo apt-get update
        sudo apt-get install -y "${package_list[@]}"
        ;;
    dnf)
        package_list=(breeze-icon-theme conky dconf fontconfig \
            gnome-extensions-app gnome-tweaks ImageMagick glib2-devel librsvg2-tools \
            python3-gobject gtk4-devel sassc)
        sudo dnf install -y "${package_list[@]}"
        ;;
    pacman)
        package_list=(breeze-icons conky dconf fontconfig \
            gnome-shell-extensions gnome-tweaks imagemagick glib2 librsvg \
            python-gobject gtk4 sassc)
        sudo pacman -Sy --needed --noconfirm "${package_list[@]}"
        ;;
esac

mkdir -p "$HOME/.local/share/fonts/MacTahoe"
cp -a "$ROOT_DIR/assets/fonts/SF-Pro" "$ROOT_DIR/assets/fonts/SF-Mono" \
    "$HOME/.local/share/fonts/MacTahoe/"
fc-cache -f "$HOME/.local/share/fonts/MacTahoe"
(cd "$ROOT_DIR/vendor/MacTahoe-gtk-theme" && ./install.sh -l --shell -i apple)
(cd "$ROOT_DIR/vendor/MacTahoe-icon-theme" && ./install.sh -t blue)
cp -a "$ROOT_DIR/assets/wallpapers/." "$HOME/Pictures/Wallpapers/MacTahoe/"

cp "$ROOT_DIR/apps/mactahoe-widgets" "$ROOT_DIR/apps/mactahoe-icon-manager" \
    "$ROOT_DIR/apps/mactahoe-weather-fetch.py" "$ROOT_DIR/apps/mactahoe-lunar-fetch.py" \
    "$ROOT_DIR/apps/color-scheme-sync.sh" "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin/mactahoe-widgets" "$HOME/.local/bin/mactahoe-icon-manager" \
    "$HOME/.local/bin/mactahoe-weather-fetch.py" "$HOME/.local/bin/mactahoe-lunar-fetch.py" \
    "$HOME/.local/bin/color-scheme-sync.sh"
cp "$ROOT_DIR/apps/lunar.py" "$HOME/.local/share/mactahoe-widgets/lunar.py"

for conf in "$ROOT_DIR"/conky/mactahoe-*.conf; do
    sed "s|@HOME@|$HOME|g" "$conf" > "$HOME/.config/conky/${conf##*/}"
done
cp "$ROOT_DIR/conky/mactahoe-widgets.lua" "$HOME/.config/conky/"
sed "s|@HOME@|$HOME|g" "$ROOT_DIR/config/weather.conf" \
    > "$HOME/.config/mactahoe-widgets/weather.conf"

EXTENSION_IDS=(blur-my-shell@aunetx globalmenu@ShiroOSL.github.io \
    just-perfection-desktop@just-perfection)
for uuid in "${EXTENSION_IDS[@]}"; do
    target="$HOME/.local/share/gnome-shell/extensions/$uuid"
    if [ -d "$target" ]; then
        mkdir -p "$BACKUP_DIR/extensions"
        cp -a "$target" "$BACKUP_DIR/extensions/"
    fi
    mkdir -p "${target%/*}"
    rm -rf "$target"
    cp -a "$ROOT_DIR/vendor/gnome-extensions/$uuid" "$target"
    if [ -d "$target/schemas" ]; then glib-compile-schemas "$target/schemas"; fi
done

gs() {
    local schema="$1"; shift
    local uuid schema_dir
    case "$schema" in
        org.gnome.shell.extensions.blur-my-shell*) uuid=blur-my-shell@aunetx ;;
        org.gnome.shell.extensions.globalmenu) uuid=globalmenu@ShiroOSL.github.io ;;
        org.gnome.shell.extensions.just-perfection) uuid=just-perfection-desktop@just-perfection ;;
        *) gsettings "$schema" "$@"; return $? ;;
    esac
    schema_dir="$HOME/.local/share/gnome-shell/extensions/$uuid/schemas"
    GSETTINGS_SCHEMA_DIR="$schema_dir" gsettings "$schema" "$@"
}

while read -r schema key value; do
    [ -n "${schema:-}" ] || continue
    if [ "$distribution_id" != ubuntu ] && { [ "$schema" = org.gnome.shell ] || [ "$schema" = org.gnome.shell.extensions.dash-to-dock ]; }; then
        continue
    fi
    if gs "$schema" writable "$key" >/dev/null 2>&1; then gs "$schema" set "$key" "$value"; fi
done < "$ROOT_DIR/config/gsettings.tsv"

wall="$HOME/Pictures/Wallpapers/MacTahoe/MacTahoe-night.jpeg"
wall_uri="$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).as_uri())' "$wall")"
gsettings set org.gnome.desktop.background picture-uri "$wall_uri"
gsettings set org.gnome.desktop.background picture-uri-dark "$wall_uri"
gsettings set org.gnome.desktop.background picture-options 'zoom'
gsettings set org.gnome.desktop.screensaver picture-uri "$wall_uri"
gsettings set org.gnome.desktop.screensaver picture-options 'zoom'

extension_ids=(user-theme@gnome-shell-extensions.gcampax.github.com \
    blur-my-shell@aunetx globalmenu@ShiroOSL.github.io \
    just-perfection-desktop@just-perfection)
if [ "$distribution_id" = ubuntu ]; then extension_ids+=(ubuntu-dock@ubuntu.com); fi
for uuid in "${extension_ids[@]}"; do
    gnome-extensions enable "$uuid" || true
done

cp "$ROOT_DIR/desktop/mactahoe-widgets.desktop" "$HOME/.local/share/applications/"
cp "$ROOT_DIR/desktop/mactahoe-icon-manager.desktop" "$HOME/.local/share/applications/"
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

if [ "$INSTALL_GDM" -eq 1 ]; then
    if [ "$distribution_id" = ubuntu ] && [ -e /usr/share/gnome-shell/theme/Yaru/gnome-shell-theme.gresource ]; then
        sudo cp -n /usr/share/gnome-shell/theme/Yaru/gnome-shell-theme.gresource \
            /usr/share/gnome-shell/theme/Yaru/gnome-shell-theme.gresource.bak
        sudo "$ROOT_DIR/vendor/MacTahoe-gtk-theme/tweaks.sh" -g -i apple -b "$wall"
        touch "$STATE_DIR/gdm-installed"
    else
        printf 'Skipping login-screen theme: this GDM theme step is currently Ubuntu/Yaru-specific.\n'
    fi
fi

update-desktop-database "$HOME/.local/share/applications" || true
printf '\nInstalled. Log out and back in to load GNOME Shell extensions.\n'
if [ "$INSTALL_GDM" -eq 1 ]; then printf 'Reboot to apply the login screen theme.\n'; fi
printf 'Widgets start only when you click Widget MacTahoe.\nBackup: %s\n' "$BACKUP_DIR"
