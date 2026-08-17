#!/usr/bin/env bash

# Read CPU and Motherboard temperatures from hwmon sensors
# CPU:         hwmon4 k10temp (Tctl)  -> labeled "C"
# Motherboard: hwmon3 acpitz          -> labeled "M"

cpu_temp=""
mb_temp=""

# Read CPU temp from k10temp (Tctl)
if [ -f /sys/class/hwmon/hwmon4/temp1_input ]; then
    cpu_raw=$(cat /sys/class/hwmon/hwmon4/temp1_input)
    cpu_temp=$((cpu_raw / 1000))
fi

# Read Motherboard temp from acpitz
if [ -f /sys/class/hwmon/hwmon3/temp1_input ]; then
    mb_raw=$(cat /sys/class/hwmon/hwmon3/temp1_input)
    mb_temp=$((mb_raw / 1000))
fi

# Determine critical state (if either temp is >= 85°C)
critical=false
if [ -n "$cpu_temp" ] && [ "$cpu_temp" -ge 85 ]; then
    critical=true
fi
if [ -n "$mb_temp" ] && [ "$mb_temp" -ge 85 ]; then
    critical=true
fi

# Build the output
if [ -n "$cpu_temp" ] && [ -n "$mb_temp" ]; then
    text="C ${cpu_temp}°  M ${mb_temp}°"
    tooltip="CPU: ${cpu_temp}°C\nMotherboard: ${mb_temp}°C"
elif [ -n "$cpu_temp" ]; then
    text="C ${cpu_temp}°"
    tooltip="CPU: ${cpu_temp}°C"
elif [ -n "$mb_temp" ]; then
    text="M ${mb_temp}°"
    tooltip="Motherboard: ${mb_temp}°C"
else
    text="N/A"
    tooltip="Temperature sensors unavailable"
fi

# Output as JSON for waybar
if [ "$critical" = true ]; then
    printf '{"text":"%s","tooltip":"%s","class":"critical"}' "$text" "$tooltip"
else
    printf '{"text":"%s","tooltip":"%s"}' "$text" "$tooltip"
fi
