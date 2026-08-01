hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )
hl.bind("SUPER + F1", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/toggle_external_only.sh"), { description = "Monitor: Toggle external only / both" })
hl.bind("SUPER + SHIFT + ALT + C", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/compact_workspaces.sh"), { description = "Workspace: Compact (remove gaps)" })
