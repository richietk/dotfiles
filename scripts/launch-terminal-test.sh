#!/usr/bin/env bash
# Wayland-aware terminal launcher for cron — sets session env vars cron doesn't inherit
export HOME=/home/richard
export USER=richard
export XDG_RUNTIME_DIR=/run/user/1000
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus

# Find the active wayland socket (usually wayland-1)
WAYLAND_SOCK=$(ls /run/user/1000/ 2>/dev/null | grep '^wayland-[0-9]' | head -1)
[ -z "$WAYLAND_SOCK" ] && exit 1
export WAYLAND_DISPLAY="$WAYLAND_SOCK"

exec /etc/profiles/per-user/richard/bin/kitty
