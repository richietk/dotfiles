#!/usr/bin/env bash
# Microphone mute toggle for Waybar
# Uses wpctl to query and toggle mic mute state

get_state() {
    # Query the default audio source (microphone) and check if muted
    # wpctl status shows: "Muted: no" or "Muted: yes"
    if command -v wpctl &>/dev/null; then
        mute_status=$(wpctl get-mute @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)
        if [ "$mute_status" = "Muted: yes" ]; then
            echo "1"  # muted
        else
            echo "0"  # not muted
        fi
    else
        echo "0"  # default to not muted if wpctl unavailable
    fi
}

toggle() {
    if command -v wpctl &>/dev/null; then
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
    fi
}

show_state() {
    state=$(get_state)
    if [ "$state" = "1" ]; then
        # Muted
        echo '{"text":"󰍭","class":"muted"}'
    else
        # Unmuted / Active
        echo '{"text":"󰍬","class":"active"}'
    fi
}

case "${1:-show}" in
    toggle) toggle; show_state ;;
    show) show_state ;;
    *) show_state ;;
esac
