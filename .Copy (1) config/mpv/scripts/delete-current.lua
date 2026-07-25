local function delete_current()
    local path = mp.get_property("path")
    if not path then return end

    local result = mp.command_native({
        name = "subprocess",
        args = { "/etc/profiles/per-user/richard/bin/trash-put", path },
        capture_stderr = true,
        capture_stdout = true,
    })

    if result.status == 0 then
        mp.osd_message("Trashed: " .. path)
        local count = mp.get_property_number("playlist-count", 1)
        if count <= 1 then
            mp.commandv("quit")
        else
            mp.commandv("playlist-next", "force")
        end
    else
        local msg = result.stderr ~= "" and result.stderr or result.stdout ~= "" and result.stdout or ("exit code " .. tostring(result.status))
        mp.osd_message("Trash failed: " .. msg)
    end
end

mp.add_key_binding("ctrl+DEL", "delete-current", delete_current)
