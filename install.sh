#!/bin/bash
# idempotent

set -e
DOTFILES="$HOME/dotfiles"

echo "==> Symlinking user configs..."
ln -sf "$DOTFILES/.zshrc" ~/.zshrc
ln -sf "$DOTFILES/.config/hypr/hyprland.conf" ~/.config/hypr/hyprland.conf
mkdir -p ~/.config/systemd/user
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

echo "==> Adding richard to input group..."
sudo usermod -aG input richard

echo "Done. Log out and back in for group membership to take effect."