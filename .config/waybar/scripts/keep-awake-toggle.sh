#!/usr/bin/env bash
# Keep-awake (idle inhibitor) toggle for Waybar
# Uses a state file to track inhibit state

STATE_FILE="/tmp/waybar-keep-awake"
PID_FILE="/tmp/waybar-keep-awake.pid"

get_state() {
    # Check if state file exists and process is still running
    if [ -f "$STATE_FILE" ] && [ -f "$PID_FILE" ]; then
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "1"  # active
            return
        fi
    fi
    echo "0"  # inactive
}

start_inhibit() {
    # Start a systemd-inhibit process and save its PID
    systemd-inhibit --why="Waybar keep-awake" --mode=block sleep &
    echo $! > "$PID_FILE"
    touch "$STATE_FILE"
}

stop_inhibit() {
    # Kill the inhibit process if it exists
    if [ -f "$PID_FILE" ]; then
        pid=$(cat "$PID_FILE")
        kill "$pid" 2>/dev/null || true
        rm -f "$PID_FILE"
    fi
    rm -f "$STATE_FILE"
}

toggle() {
    state=$(get_state)
    if [ "$state" = "1" ]; then
        stop_inhibit
    else
        start_inhibit
    fi
}

show_state() {
    state=$(get_state)
    if [ "$state" = "1" ]; then
        echo '{"text":"󰄪","class":"active"}'
    else
        echo '{"text":"󰄪"}'
    fi
}

case "${1:-show}" in
    toggle) toggle; show_state ;;
    show) show_state ;;
    *) show_state ;;
esac
