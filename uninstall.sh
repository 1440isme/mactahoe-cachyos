#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [ "$EUID" -eq 0 ]; then
    printf 'Run this uninstaller as your normal user, without sudo.\n' >&2
    exit 1
fi
STATE_DIR="$HOME/.local/state/mactahoe-ubuntu"
BACKUP_DIR=""
if [ -f "$STATE_DIR/latest-backup" ]; then BACKUP_DIR="$(cat "$STATE_DIR/latest-backup")"; fi
ICON_MANAGER_DIR="$HOME/.local/share/mactahoe-icon-manager"
LOCAL_APPLICATIONS="$HOME/.local/share/applications"

restore_item() {
    local relative="$1"
    rm -rf "$HOME/$relative"
    if [ -n "$BACKUP_DIR" ] && [ -e "$BACKUP_DIR/home/$relative" ]; then
        mkdir -p "$HOME/$(dirname "$relative")"
        cp -a "$BACKUP_DIR/home/$relative" "$HOME/$relative"
    fi
}

systemctl --user disable --now color-scheme-sync.service 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/color-scheme-sync.service"
systemctl --user daemon-reload 2>/dev/null || true
"$HOME/.local/bin/mactahoe-widgets" stop 2>/dev/null || true
rm -rf "$HOME/.cache/mactahoe-widgets/runtime" "$HOME/.cache/mactahoe-widgets/pids"

if [ -d "$ICON_MANAGER_DIR/backups" ]; then
    mkdir -p "$LOCAL_APPLICATIONS"
    for backup in "$ICON_MANAGER_DIR"/backups/*.desktop.bak; do
        [ -f "$backup" ] || continue
        desktop_id="${backup##*/}"
        desktop_id="${desktop_id%.bak}"
        rm -f "$LOCAL_APPLICATIONS/$desktop_id"
        cp -a "$backup" "$LOCAL_APPLICATIONS/$desktop_id"
    done
fi
if [ -d "$LOCAL_APPLICATIONS" ]; then
    for desktop_file in "$LOCAL_APPLICATIONS"/*.desktop; do
        [ -f "$desktop_file" ] || continue
        if grep -Fq "$ICON_MANAGER_DIR/icons/" "$desktop_file"; then
            rm -f "$desktop_file"
        fi
    done
fi
rm -rf "$ICON_MANAGER_DIR"

for path in .local/bin/mactahoe-widgets .local/bin/mactahoe-icon-manager \
    .local/bin/mactahoe-weather-fetch.py .local/bin/mactahoe-lunar-fetch.py \
    .local/bin/am-lich-viet-nam .local/bin/image-compressor \
    .local/bin/color-scheme-sync.sh .local/share/mactahoe-widgets \
    .local/share/applications/mactahoe-widgets.desktop \
    .local/share/applications/mactahoe-icon-manager.desktop \
    .local/share/applications/vn.ihoan.AmLich.desktop \
    .local/share/applications/vn.ihoan.ImageCompressor.desktop \
    .local/share/mactahoe-apps/am-lich-viet-nam \
    .local/share/mactahoe-apps/image-compressor \
    .local/share/icons/hicolor/scalable/apps/vn.ihoan.AmLich.svg \
    .local/share/icons/hicolor/scalable/apps/vn.ihoan.ImageCompressor.svg \
    .local/share/fonts/MacTahoe .config/mactahoe-widgets/weather.conf \
    .config/mactahoe-widgets/settings.json \
    Pictures/Wallpapers/MacTahoe; do
    restore_item "$path"
done

for path in "$HOME"/.config/conky/mactahoe-*; do
    [ ! -e "$path" ] || rm -f "$path"
done
if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR/home/.config/conky" ]; then
    cp -a "$BACKUP_DIR/home/.config/conky/." "$HOME/.config/conky/"
fi

for uuid in blur-my-shell@aunetx globalmenu@ShiroOSL.github.io \
    just-perfection-desktop@just-perfection; do
    gnome-extensions disable "$uuid" 2>/dev/null || true
    rm -rf "$HOME/.local/share/gnome-shell/extensions/$uuid"
    if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR/extensions/$uuid" ]; then
        cp -a "$BACKUP_DIR/extensions/$uuid" "$HOME/.local/share/gnome-shell/extensions/"
    fi
done

for profile_root in "$HOME/snap/firefox/common/.mozilla/firefox" "$HOME/.mozilla/firefox"; do
    [ -d "$profile_root" ] || continue
    while IFS= read -r -d '' prefs; do
        profile="${prefs%/prefs.js}"
        if [ -f "$profile/user.js.mactahoe-backup" ]; then
            mv "$profile/user.js.mactahoe-backup" "$profile/user.js"
        elif [ -f "$profile/user.js" ]; then
            grep -Fvx -f "$ROOT_DIR/config/firefox-user.js" "$profile/user.js" > "$profile/user.js.tmp" || true
            mv "$profile/user.js.tmp" "$profile/user.js"
        fi
        if [ -d "$profile/chrome.mactahoe-backup" ]; then
            rm -rf "$profile/chrome"
            mv "$profile/chrome.mactahoe-backup" "$profile/chrome"
        else
            rm -rf "$profile/chrome/MacTahoe"
            rm -f "$profile/chrome/customChrome.css" "$profile/chrome/userChrome.css" \
                "$profile/chrome/userContent.css"
        fi
    done < <(find "$profile_root" -mindepth 2 -maxdepth 4 -type f -name prefs.js -print0)
done

if [ -n "$BACKUP_DIR" ]; then
    for path in gtk-3.0 gtk-4.0; do
        rm -rf "$HOME/.config/$path"
        if [ -d "$BACKUP_DIR/$path" ]; then
            cp -a "$BACKUP_DIR/$path" "$HOME/.config/"
        fi
    done
    if [ -f "$BACKUP_DIR/dconf-before.ini" ]; then
        printf 'Restore the complete pre-install GNOME settings backup? [Y/n] '
        read -r answer
        if [[ ! "$answer" =~ ^[Nn]$ ]]; then
            for path in /org/gnome/desktop/interface/ /org/gnome/desktop/background/ \
                /org/gnome/desktop/screensaver/ /org/gnome/desktop/wm/preferences/ \
                /org/gnome/shell/; do
                dconf reset -f "$path"
            done
            dconf load / < "$BACKUP_DIR/dconf-before.ini"
        else
            while read -r schema key value; do
                [ -n "${schema:-}" ] || continue
                case "$schema" in
                    org.gnome.shell.extensions.blur-my-shell*) uuid=blur-my-shell@aunetx ;;
                    org.gnome.shell.extensions.globalmenu) uuid=globalmenu@ShiroOSL.github.io ;;
                    org.gnome.shell.extensions.just-perfection) uuid=just-perfection-desktop@just-perfection ;;
                    *) uuid="" ;;
                esac
                if [ -n "$uuid" ]; then
                    GSETTINGS_SCHEMA_DIR="$ROOT_DIR/vendor/gnome-extensions/$uuid/schemas" \
                        gsettings reset "$schema" "$key" 2>/dev/null || true
                else
                    gsettings reset "$schema" "$key" 2>/dev/null || true
                fi
            done < "$ROOT_DIR/config/gsettings.tsv"
            gsettings reset org.gnome.desktop.background picture-uri || true
            gsettings reset org.gnome.desktop.background picture-uri-dark || true
            gsettings reset org.gnome.desktop.screensaver picture-uri || true
            gsettings reset org.gnome.desktop.background picture-options || true
            gsettings reset org.gnome.desktop.screensaver picture-options || true
        fi
    fi
fi

if [ -n "$BACKUP_DIR" ] && [ -f "$BACKUP_DIR/apt-packages-installed-by-mactahoe" ]; then
    mapfile -t apt_packages_to_remove < <(
        while IFS= read -r package; do
            [ -n "$package" ] || continue
            dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null | grep -q '^ii' &&
                printf '%s\n' "$package"
        done < "$BACKUP_DIR/apt-packages-installed-by-mactahoe"
    )
    if [ "${#apt_packages_to_remove[@]}" -gt 0 ]; then
        printf 'Removing apt packages newly installed by MacTahoe: %s\n' "${apt_packages_to_remove[*]}"
        sudo apt-get purge -y "${apt_packages_to_remove[@]}"
    fi
elif [ -n "$BACKUP_DIR" ] && [ -f "$BACKUP_DIR/apt-tracking-legacy" ]; then
    legacy_packages=(breeze-icon-theme conky-all dconf-cli fontconfig \
        gir1.2-adw-1 gir1.2-gtk-4.0 gnome-shell-extension-manager \
        gnome-shell-extension-user-theme gnome-tweaks imagemagick \
        libglib2.0-dev-bin librsvg2-bin python3-gi python3-pil sassc)
    printf 'This installation predates package tracking. Purge installed MacTahoe package-list items?\n'
    printf 'This may also remove packages that were installed before MacTahoe. [Y/n] '
    read -r answer
    if [[ ! "$answer" =~ ^[Nn]$ ]]; then
        installed_legacy_packages=()
        for package in "${legacy_packages[@]}"; do
            dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null | grep -q '^ii' &&
                installed_legacy_packages+=("$package")
        done
        if [ "${#installed_legacy_packages[@]}" -gt 0 ]; then
            sudo apt-get purge -y "${installed_legacy_packages[@]}"
        fi
    fi
fi

(cd "$ROOT_DIR/vendor/MacTahoe-gtk-theme" && ./install.sh -r || true)
(cd "$ROOT_DIR/vendor/MacTahoe-icon-theme" && ./install.sh -r || true)
if [ -f "$STATE_DIR/gdm-installed" ]; then
    sudo "$ROOT_DIR/vendor/MacTahoe-gtk-theme/tweaks.sh" -g -r || true
    rm -f "$STATE_DIR/gdm-installed"
fi
if [ -n "$BACKUP_DIR" ]; then
    for path in "$BACKUP_DIR/home/.themes"/MacTahoe-* "$BACKUP_DIR/home/.local/share/icons"/MacTahoe*; do
        [ ! -e "$path" ] || cp -a "$path" "$HOME/${path#"$BACKUP_DIR/home/"}"
    done
fi
fc-cache -f "$HOME/.local/share/fonts" 2>/dev/null || true
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
gtk-update-icon-cache -q -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
rm -f "$STATE_DIR/latest-backup"
printf 'Uninstall finished. Pre-existing system packages were preserved.\n'
