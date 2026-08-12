set shell := ["zsh", "-euo", "pipefail", "-c"]

SSD_MOUNT := "/run/media/richard/Expansion"
RESTIC_REPO := SSD_MOUNT + "/backups/restic_repo"

# Update flake inputs and rebuild NixOS
update:
    nix flake update --flake ~/dotfiles/nix-config
    sudo nixos-rebuild switch --flake ~/dotfiles/nix-config#nixos

# Rebuild NixOS and push dotfiles on success
rebuild:
    sudo nixos-rebuild switch --flake ~/dotfiles/nix-config#nixos
    cd ~/dotfiles && \
        find . -type l -lname '/nix/store/*' -exec git rm --cached {} \; 2>/dev/null || true && \
        git add . && { git commit -m "update dotfiles" && git push || true; }

# Remove generations older than 7 days, GC store, optimise
cleanup:
    sudo nix-collect-garbage --delete-older-than 7d
    nix store gc
    nix store optimise

# Delete Go module cache, npm cache, Firefox/uv/go-build/mesa caches
clean:
    command -v go &>/dev/null && go clean -modcache -cache || rm -rf ~/go/pkg/mod ~/.cache/go-build
    command -v npm &>/dev/null && npm cache clean --force || rm -rf ~/.npm/_cacache
    command -v uv &>/dev/null && uv cache clean || rm -rf ~/.cache/uv
    rm -rf ~/.cache/mozilla ~/.cache/mesa_shader_cache

# Run all backups: restic to local SSD, then sync to ProtonDrive and Google Drive
backup:
    #!/usr/bin/env zsh
    SSD_MOUNT="{{SSD_MOUNT}}"
    RESTIC_REPO="{{RESTIC_REPO}}"

    mountpoint -q "$SSD_MOUNT" || { echo "SSD not mounted at $SSD_MOUNT" >&2; exit 1; }

    [[ -f "$RESTIC_REPO/config" ]] || restic -r "$RESTIC_REPO" init

    echo "==> Backing up to $RESTIC_REPO..."
    restic -r "$RESTIC_REPO" backup --verbose \
        --exclude "$HOME/.cache" \
        --exclude "$HOME/.nix-profile" \
        --exclude "$HOME/.nix-defexpr" \
        --exclude "$HOME/.npm" \
        --exclude "$HOME/.var" \
        --exclude "$HOME/.mozilla" \
        --exclude "$HOME/.config/mozilla" \
        --exclude "$HOME/.config/google-chrome" \
        --exclude "$HOME/.config/discord" \
        --exclude "$HOME/.config/Code" \
        --exclude "$HOME/.config/libreoffice" \
        --exclude "$HOME/.config/.venv" \
        --exclude "$HOME/.local/share/Trash" \
        --exclude "$HOME/.local/share/baloo" \
        --exclude "$HOME/.zcompdump*" \
        --exclude "$HOME/.Copy (1) config" \
        --exclude "**/.venv/" \
        --exclude "*.lock" \
        "$HOME"

    echo "==> Pruning old snapshots..."
    restic -r "$RESTIC_REPO" forget --keep-last 10 --prune

    echo "==> Syncing to ProtonDrive..."
    rclone copy "$HOME/Documents/docs" pdrive:backup/docs \
        --protondrive-replace-existing-draft=true -P

    echo "==> Syncing restic repo to GoogleDrive..."
    rclone copy "$RESTIC_REPO" gdrive:restic_repo \
        --progress --transfers 4 --checkers 8 \
        --retries 10 --low-level-retries 20 \
        --timeout 5m --contimeout 1m --stats 5s

    echo "==> Backup done."
