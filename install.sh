#!/bin/bash
# idempotent

set -euo pipefail
DOTFILES="$HOME/dotfiles"

for cmd in ln mkdir systemctl sudo; do
    command -v "$cmd" &>/dev/null || { echo "Required command not found: $cmd" >&2; exit 1; }
done
for cmd in udevadm usermod; do
    command -v "$cmd" &>/dev/null || { echo "Required command not found: $cmd (install systemd/shadow)" >&2; exit 1; }
done

echo "==> Symlinking user configs..."
ln -sf "$DOTFILES/.zshrc" ~/.zshrc

# KDE Plasma
ln -sf "$DOTFILES/.config/kglobalshortcutsrc"                        ~/.config/kglobalshortcutsrc
ln -sf "$DOTFILES/.config/kwinrc"                                     ~/.config/kwinrc
ln -sf "$DOTFILES/.config/kdeglobals"                                 ~/.config/kdeglobals
ln -sf "$DOTFILES/.config/plasmashellrc"                              ~/.config/plasmashellrc
ln -sf "$DOTFILES/.config/plasma-org.kde.plasma.desktop-appletsrc"   ~/.config/plasma-org.kde.plasma.desktop-appletsrc
ln -sf "$DOTFILES/.config/katerc"                                     ~/.config/katerc
ln -sf "$DOTFILES/.config/katevirc"                                   ~/.config/katevirc

# Hyprland
ln -sf "$DOTFILES/.config/hypr/hyprland.conf" ~/.config/hypr/hyprland.conf

# Double Commander
mkdir -p ~/.config/doublecmd
ln -sf "$DOTFILES/.config/doublecmd/doublecmd.xml"    ~/.config/doublecmd/doublecmd.xml
ln -sf "$DOTFILES/.config/doublecmd/shortcuts.scf"    ~/.config/doublecmd/shortcuts.scf
ln -sf "$DOTFILES/.config/doublecmd/colors.json"      ~/.config/doublecmd/colors.json
ln -sf "$DOTFILES/.config/doublecmd/highlighters.xml" ~/.config/doublecmd/highlighters.xml
ln -sf "$DOTFILES/.config/doublecmd/multiarc.ini"     ~/.config/doublecmd/multiarc.ini

# DeadBeeF
mkdir -p ~/.config/deadbeef
ln -sf "$DOTFILES/.config/deadbeef/config"    ~/.config/deadbeef/config
ln -sf "$DOTFILES/.config/deadbeef/dspconfig" ~/.config/deadbeef/dspconfig

# mpv
mkdir -p ~/.config/mpv
ln -sf "$DOTFILES/.config/mpv/mpv.conf" ~/.config/mpv/mpv.conf

# systemd user service
mkdir -p ~/.config/systemd/user || { echo "Failed to create ~/.config/systemd/user" >&2; exit 1; }
ln -sf "$DOTFILES/.config/systemd/user/touchpad-filter.service" \
       ~/.config/systemd/user/touchpad-filter.service

echo "==> Installing system scripts (needs sudo)..."
sudo cp "$DOTFILES/scripts/touchpad-filter" /usr/local/bin/touchpad-filter
sudo cp "$DOTFILES/scripts/reset-touchpad"  /usr/local/bin/reset-touchpad
sudo chmod 755 /usr/local/bin/touchpad-filter /usr/local/bin/reset-touchpad

echo "==> Installing udev rule..."
sudo cp "$DOTFILES/system/99-uinput.rules" /etc/udev/rules.d/99-uinput.rules
sudo udevadm trigger

echo "==> Installing sudoers fragment..."
sudo cp "$DOTFILES/system/touchpad-reset" /etc/sudoers.d/touchpad-reset
sudo chmod 440 /etc/sudoers.d/touchpad-reset

echo "==> Enabling systemd user service..."
systemctl --user daemon-reload
systemctl --user enable --now touchpad-filter

echo "==> Adding $USER to input group..."
sudo usermod -aG input "$USER"

echo "Done. Log out and back in for group membership to take effect."