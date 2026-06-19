#!/bin/bash
# Toggle between: both monitors / external only (eDP-1 disabled)
BUILTIN="eDP-1"
EXTERNAL="HDMI-A-1"

IS_DISABLED=$(hyprctl monitors all -j | python3 -c "
import json, sys
monitors = json.load(sys.stdin)
m = next((x for x in monitors if x['name'] == '$BUILTIN'), None)
print('true' if m and m.get('disabled') else 'false')
")

if [ "$IS_DISABLED" = "true" ]; then
    # Re-enable built-in, put external back to the right
    hyprctl eval "hl.monitor({ output = '$BUILTIN', mode = '2880x1800@90', position = '0x0', scale = 1, disabled = false })"
    hyprctl eval "hl.monitor({ output = '$EXTERNAL', mode = '1920x1080@60', position = '2880x0', scale = 1 })"
else
    # Disable built-in, move external to 0x0
    hyprctl eval "hl.monitor({ output = '$BUILTIN', disabled = true })"
    hyprctl eval "hl.monitor({ output = '$EXTERNAL', mode = '1920x1080@60', position = '0x0', scale = 1 })"
fi
