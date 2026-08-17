#!/usr/bin/env bash
# Notification unread count badge for Waybar
# Shows a badge with unread notification count

# Check if dbus notification service is available
if ! command -v dbus-send &>/dev/null; then
    echo '{"text":"","class":"empty"}'
    exit 0
fi

# Try to get unread notifications from mako/dbus
# Fallback: check if notification daemon is running and count via its protocol
if command -v makoctl &>/dev/null; then
    count=$(makoctl list 2>/dev/null | grep -c "id")
else
    # Fallback to checking if any notification is recent
    count=0
fi

if [ "$count" -gt 0 ]; then
    echo "{\"text\":\"󰂄 $count\",\"class\":\"unread\"}"
else
    echo '{"text":"","class":"empty"}'
fi
