#!/usr/bin/env bash
# Pack all occupied workspaces left: [1,_,_,4,a,_,7] -> [1,2,3,4,5,_,_]
# Windows stay on their original monitors. Uses Hyprland v0.55+ Lua dispatch.

# "id monitor" pairs of occupied workspaces, sorted by id
ws_data=$(hyprctl workspaces -j | jq -r \
    '[.[] | select(.id > 0 and .windows > 0)] | sort_by(.id) | .[] | "\(.id) \(.monitor)"')

target=1
while read -r ws_id ws_mon; do
    if [[ "$ws_id" -ne "$target" ]]; then
        while IFS= read -r addr; do
            [[ -n "$addr" ]] && hyprctl dispatch \
                "hl.dsp.window.move({workspace = ${target}, window = 'address:${addr}', follow = false})" > /dev/null
        done < <(hyprctl clients -j | jq -r --argjson ws "$ws_id" \
            '.[] | select(.workspace.id == $ws) | .address')
        # New workspaces spawn on the active monitor; pin it back to the source monitor
        hyprctl dispatch "hl.dsp.workspace.move({workspace = ${target}, monitor = '${ws_mon}'})" > /dev/null
    fi
    target=$(( target + 1 ))
done <<< "$ws_data"
