alias venvact='source ~/venv/bin/activate'

# --- Per-project venv management via uv (default name: .venv) ---
venv-create() {
    local name="${1:-.venv}"
    uv venv "$name" || return 1
    echo "Created venv at ./$name (uv)"
}

venv-activate() {
    local name="${1:-.venv}"
    if [[ -f "$name/bin/activate" ]]; then
        source "$name/bin/activate"
    else
        echo "No venv found at ./$name"
        return 1
    fi
}

venv-deactivate() {
    if type deactivate &>/dev/null; then
        deactivate
    else
        echo "No venv active."
    fi
}

venv-delete() {
    local name="${1:-.venv}"
    local confirm
    if [[ -d "$name" ]]; then
        read "confirm?Delete venv at ./$name? [y/N] "
        if [[ "$confirm" == [Yy] ]]; then
            rm -rf "$name"
            echo "Deleted ./$name"
        else
            echo "Aborted."
        fi
    else
        echo "No venv found at ./$name"
        return 1
    fi
}

venvlist() {
    local venvs=()
    local i=1

    echo "Scanning $HOME for virtual environments..."
    while IFS= read -r cfg; do
        venvs+=("$(dirname "$cfg")")
    done < <(find "$HOME" -name "pyvenv.cfg" -not -path "*/.git/*" 2>/dev/null)

    if (( ${#venvs[@]} == 0 )); then
        echo "No virtual environments found."
        return 0
    fi

    echo "\nFound ${#venvs[@]} virtual environment(s):\n"
    local venv size
    for venv in "${venvs[@]}"; do
        size="$(du -sh "$venv" 2>/dev/null | cut -f1)"
        echo "  $i) [$size]\t$venv"
        (( i++ ))
    done

    echo ""
    local choice
    read "choice?Enter number to delete (or press Enter to cancel): "
    [[ -z "$choice" ]] && { echo "Cancelled."; return 0; }

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#venvs[@]} )); then
        echo "Invalid choice."
        return 1
    fi

    local target="${venvs[$choice]}"
    local confirm
    read "confirm?Delete '$target'? [y/N] "
    if [[ "$confirm" == [Yy] ]]; then
        rm -rf "$target"
        echo "Deleted $target"
    else
        echo "Aborted."
    fi
}
