#!/usr/bin/env bash
# Notifications mute toggle for Waybar
# Toggles mako pause/unpause state

STATE_FILE="/tmp/waybar-notif-muted"

toggle() {
    if [ -f "$STATE_FILE" ]; then
        rm -f "$STATE_FILE"
        # Resume notifications (makoctl mode -s sets the active mode set)
        if command -v makoctl &>/dev/null; then
            makoctl mode -s default 2>/dev/null || true
        fi
    else
        touch "$STATE_FILE"
        # Pause notifications
        if command -v makoctl &>/dev/null; then
            makoctl mode -s do-not-disturb 2>/dev/null || true
        fi
    fi
}

get_state() {
    if [ -f "$STATE_FILE" ]; then
        echo "1"  # muted/paused
    else
        echo "0"  # active
    fi
}

show_state() {
    state=$(get_state)
    if [ "$state" = "1" ]; then
        # Notifications paused
        echo '{"text":"󰫖","class":"active"}'
    else
        # Notifications active
        echo '{"text":"󰂀"}'
    fi
}

case "${1:-show}" in
    toggle) toggle; show_state ;;
    show) show_state ;;
    *) show_state ;;
esac
