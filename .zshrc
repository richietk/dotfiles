export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# ============================================================
#  Personal zsh config
# ============================================================

# --- Quickshell ---
alias qsrestart='pkill qs; sleep 0.5; qs -c ii &'

# --- Hyprland info ---
alias hmon='hyprctl monitors'
alias hcl='hyprctl clients'
alias hwork='hyprctl workspaces'
alias hdev='hyprctl devices'        # input devices (mice, keyboards)
alias hlay='hyprctl layers'         # active layer surfaces (bars, overlays)
alias hrel='hyprctl reload'
alias hkill='hyprctl kill'          # click to kill a window
alias hver='hyprctl version'
alias hcf="nano $HOME/.config/hypr/hyprland.conf"

# --- mem users ---
alias memusers='ps axo rss,comm --sort=-rss | head -n 6 | awk '\''NR==1 {print $1, $2; next} {printf "%.2f MB\t%s\n", $1/1024, $2}'\'''
alias memuserspriv='ps axo pid,comm --sort=-rss | head -n 6 | awk '\''NR==1 {next} {print $1, $2}'\'' | while read pid name; do priv=$(awk '\''/^Private_Dirty/{sum+=$2} END{printf "%.2f MB", sum/1024}'\'' /proc/$pid/smaps 2>/dev/null); echo "$priv\t$name"; done | sort -rn'

# --- Disk mount/unmount ---
mntdisk() {
    local disks=()
    local i=1
    echo "Unmounted partitions:"
    while IFS= read -r line; do
        disks+=("$line")
        echo "  $i) $line"
        (( i++ ))
    done < <(lsblk -rpo NAME,TYPE,SIZE,MOUNTPOINT | awk '$2=="part" && $4=="" {print $1, $3}')

    if (( ${#disks[@]} == 0 )); then
        echo "No unmounted partitions found."
        return 1
    fi

    local choice
    read "choice?Pick number: "
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#disks[@]} )); then
        echo "Invalid choice."
        return 1
    fi

    local dev="${disks[$choice]%% *}"
    udisksctl mount -b "$dev"
}

unmntdisk() {
    local disks=()
    local i=1
    echo "Mounted partitions:"
    while IFS= read -r line; do
        disks+=("$line")
        echo "  $i) $line"
        (( i++ ))
    done < <(lsblk -rpo NAME,TYPE,SIZE,MOUNTPOINT | awk '$2=="part" && $4!="" && $4!="/" && $4!~/^\/(boot|home|var|tmp|run\/user|run\/lock|sys|proc|efi)/ {print $1, $3, $4}')

    if (( ${#disks[@]} == 0 )); then
        echo "No unmountable partitions found."
        return 1
    fi

    local choice
    read "choice?Pick number: "
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#disks[@]} )); then
        echo "Invalid choice."
        return 1
    fi

    local dev="${disks[$choice]%% *}"
    udisksctl unmount -b "$dev"
}

# --- zoxide ---
eval "$(zoxide init zsh)"

# --- Aliases with colors ---
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fafe='fastfetch'
alias please='sudo'
alias e='nvim'
alias f='sudo -E nnn -H'
alias c='clear'

# --- zsh config maintenance (renamed from the fish* aliases) ---
alias zshpwd="echo ~/.zshrc"
alias zshcopy="copy ~/.zshrc"
alias sourcezsh='source ~/.zshrc'
alias zshconfig='nano ~/.zshrc'
alias htopcopy="copy 'ps auxf'"

zshcfgsrc() {
  if [[ "$1" == "-v" ]]; then
    nvim ~/.zshrc
  elif [[ "$1" == "-k" ]]; then
    kate ~/.zshrc
  else
    nano ~/.zshrc
  fi
  source ~/.zshrc
}


temps() {
  sensors | awk '
    /mt7921/   { chip="wifi" }
    /acpitz/   { chip="mb" }
    /edge:/      { print "GPU:         " $2 }
    /Tctl:/      { print "CPU:         " $2 }
    /Composite:/ { print "SSD:         " $2 }
    /temp1:/ && chip=="wifi" { print "Wi-Fi:       " $2 }
    /temp1:/ && chip=="mb"   { print "Motherboard: " $2 }
  '
}


# --- Virtual environment shortcuts ---
alias venvact='source ~/venv/bin/activate'

# --- irq balance checker ---
irqgini() { python3 "$HOME/dotfiles/scripts/irqgini.py" "$@"; }

# --- downloads / documents organizer ---
dlorg() { python3 "$HOME/dotfiles/scripts/downloads_organizer.py" "$@"; }

export PATH="$HOME/dotfiles/scripts:$PATH"
[[ -f ~/.zshrc.secrets ]] && source ~/.zshrc.secrets
# encryption
alias ecvault="fusermount3 -u ~/Documents/Vault"
alias dcvault="gocryptfs ~/.vault-encrypted ~/Documents/Vault && obsidian"

# --- Directory shortcuts ---
SSD_MOUNT="/run/media/$USER/7ABF-7932"
alias ssd='cd "$SSD_MOUNT"'
alias richard="cd $HOME"
alias thesis="cd $HOME/Documents/Thesis"
alias config='cd ~/.config'
alias kdeconf='cd ~/.config'
alias ddls="cd $HOME/Downloads"
alias docs="cd $HOME/Documents"

# --- System shortcuts ---
alias syslog='journalctl -f'
alias slep='systemctl suspend'
# NOTE: $1/$2 are escaped (\$1 \$2) so zsh leaves them for perl, not the shell.
alias snakern="perl-rename 's/([a-z])([A-Z])/\$1_\$2/g; y/A-Z/a-z/; s/[\s\-]+/_/g; s/[^a-z0-9_.]//g; s/_+/_/g' *"

# --- Per-project venv management (default name: .venv) ---
venv-create() {
    local name="${1:-.venv}"
    python3 -m venv "$name"
    echo "Created venv at ./$name"
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

# --- Functions ---
libcalc() {
    libreoffice --calc "$@"
}

# mkdir + cd in one
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Compress PDFs in the current directory
pdfcompress() {
    local pdfs=(*.pdf(.N))   # (.N) => regular files only, no error if none

    if (( ${#pdfs[@]} == 0 )); then
        echo "No PDFs found in current directory."
        return 1
    fi

    mkdir -p orig_pdfs

    local pdf filename
    for pdf in $pdfs; do
        filename="$(basename "$pdf")"
        mv "$pdf" "orig_pdfs/$filename"
        echo "Compressing $filename..."
        if gs -sDEVICE=pdfwrite \
              -dCompatibilityLevel=1.4 \
              -dPDFSETTINGS=/ebook \
              -dNOPAUSE \
              -dQUIET \
              -dBATCH \
              -sOutputFile="$filename" \
              "orig_pdfs/$filename"; then
            echo "✓ $filename"
        else
            echo "✗ Failed: $filename"
        fi
    done

    echo "Done. Originals in ./orig_pdfs/"
}

# Kill by name
killn() {
    kill ${(f)"$(pgrep "$1")"}
}

# Install/remove pkg
pmddl() {
    sudo pacman -S "$1"
}

pmrm() {
    sudo pacman -R "$1"
}

# Check files if identical
sametest() {
    if (( $# != 2 )); then
        echo "Usage: sametest <file1> <file2>"
        return 1
    fi

    if cmp -s "$1" "$2"; then
        echo "✓ Identical"
    else
        echo "✗ Different"
    fi
}

# Backup using restic — local SSD (default) or Google Drive (-g flag)
# Repos: $SSD_MOUNT/backup/restic_repo  or  rclone:gdrive:backup/restic_repo
# Retention: 7 daily, 4 weekly, 6 monthly snapshots kept after each run.
contentbak() {
    local gdrive=false arg
    for arg in "$@"; do
        [[ "$arg" == "-g" ]] && gdrive=true
    done

    local repo
    if [[ "$gdrive" == true ]]; then
        command -v rclone &>/dev/null || { echo "rclone not installed." >&2; return 1; }
        rclone listremotes | grep -q "^gdrive:" \
            || { echo "rclone remote 'gdrive' not configured. Run: rclone config" >&2; return 1; }
        repo="rclone:gdrive:backup/restic_repo"
    else
        [[ -d "$SSD_MOUNT" ]] || { echo "Drive not mounted at $SSD_MOUNT." >&2; return 1; }
        repo="$SSD_MOUNT/backup/restic_repo"
    fi

    local sources=(
        $HOME/.config $HOME/Desktop $HOME/Documents $HOME/Downloads
        $HOME/Music $HOME/Pictures $HOME/Videos $HOME/dotfiles
    )
    local excludes=(
        --exclude "$HOME/.config/google-chrome"
        --exclude "$HOME/.config/discord"
        --exclude "$HOME/.config/mozilla"
        --exclude "$HOME/.config/Code"
        --exclude "$HOME/.config/libreoffice"
        --exclude "$HOME/.config/.venv"
        --exclude "**/.venv/"
        --exclude "*.lock"
    )

    # Init repo on first use
    if ! restic -r "$repo" snapshots -q 2>/dev/null; then
        echo "Initializing restic repo at $repo..."
        restic -r "$repo" init || return 1
    fi

    echo "Backing up to $repo..."
    restic -r "$repo" backup --verbose "${excludes[@]}" "${sources[@]}" || return 1

    echo "Pruning old snapshots..."
    restic -r "$repo" forget --keep-last 10 --prune

    echo "Done → $repo"
}

# Old rsync/rclone-based backup (kept for reference)
# Backup to local SSD (default) or Google Drive (-g flag)
# Add -p to pack everything into a single tar.gz
contentbak_old() {
    local pack=false gdrive=false arg
    for arg in "$@"; do
        [[ "$arg" == "-p" ]] && pack=true
        [[ "$arg" == "-g" ]] && gdrive=true
    done

    local date_str="$(date +%Y%m%d)"
    local dirs=(
        $HOME/.config $HOME/Desktop $HOME/Documents $HOME/Downloads
        $HOME/Music $HOME/Pictures $HOME/Videos $HOME/dotfiles
    )
    local tar_excl=(
        --exclude="$HOME/.config/google-chrome"
        --exclude="$HOME/.config/discord"
        --exclude="$HOME/.config/mozilla"
        --exclude="$HOME/.config/Code"
        --exclude="$HOME/.config/libreoffice"
        --exclude="$HOME/.config/.venv"
        --exclude='*.lock'
    )
    local cfg_rsync_excl=(
        --exclude='google-chrome/' --exclude='discord/' --exclude='mozilla/'
        --exclude='Code/' --exclude='libreoffice/' --exclude='.venv/' --exclude='*.lock'
    )

    local remote="gdrive"
    local dest
    if [[ "$gdrive" == true ]]; then
        dest="${remote}:backup/content_backups/content_bak_${date_str}"
    else
        dest="$SSD_MOUNT/backup/content_backups/content_bak_${date_str}"
    fi

    if [[ "$gdrive" == true ]]; then
        command -v rclone &>/dev/null || { echo "rclone not installed." >&2; return 1; }
        rclone listremotes | grep -q "^${remote}:" \
            || { echo "rclone remote '$remote' not configured. Run: rclone config" >&2; return 1; }

        local tmpdir="/tmp/contentbak_${date_str}"
        mkdir -p "$tmpdir"

        if [[ "$pack" == true ]]; then
            echo "Packing archive..."
            tar czf "$tmpdir/content_bak_${date_str}.tar.gz" "${tar_excl[@]}" "${dirs[@]}"
            rclone copy --transfers=16 --checkers=32 --drive-chunk-size=64M --progress \
                "$tmpdir/content_bak_${date_str}.tar.gz" "$dest/"
        else
            echo "Archiving .config..."
            tar czf "$tmpdir/config.tar.gz" "${tar_excl[@]}" $HOME/.config
            rclone copy --transfers=16 --checkers=32 --drive-chunk-size=64M --progress \
                "$tmpdir/config.tar.gz" "$dest/"
            local dir
            for dir in "${dirs[@]:1}"; do
                echo "Uploading $(basename "$dir")..."
                rclone copy --links=false --ignore-errors --update \
                    --exclude='*.lock' --exclude='.venv/' \
                    --transfers=16 --checkers=32 --drive-chunk-size=64M --progress \
                    "$dir" "$dest/$(basename "$dir")/"
            done
        fi
        rm -rf "$tmpdir"
    else
        [[ -d "$SSD_MOUNT" ]] || { echo "Drive not mounted at $SSD_MOUNT." >&2; return 1; }
        mkdir -p "$dest"

        if [[ "$pack" == true ]]; then
            local tmpfile="/tmp/content_bak_${date_str}.tar.gz"
            echo "Packing archive..."
            tar czf "$tmpfile" "${tar_excl[@]}" "${dirs[@]}"
            mv "$tmpfile" "$dest/"
        else
            local dir
            for dir in "${dirs[@]}"; do
                echo "Copying $(basename "$dir")..."
                if [[ "$dir" == $HOME/.config ]]; then
                    rsync -rpt --no-links --ignore-errors --update \
                        "${cfg_rsync_excl[@]}" --info=progress2 "$dir" "$dest/"
                else
                    rsync -rpt --no-links --ignore-errors --update \
                        --exclude='*.lock' --info=progress2 "$dir" "$dest/"
                fi
            done
        fi
    fi
    echo "Done → $dest"
}

# IP info
myip() {
    local v4="$(curl -s -4 --max-time 5 ifconfig.me 2>/dev/null)"
    local v6="$(curl -s -6 --max-time 5 ifconfig.me 2>/dev/null)"
    local info="$(curl -s --max-time 5 ipinfo.io 2>/dev/null)"

    local city="$(echo "$info"    | jq -r '.city    // "N/A"')"
    local region="$(echo "$info"  | jq -r '.region  // "N/A"')"
    local country="$(echo "$info" | jq -r '.country // "N/A"')"
    local org="$(echo "$info"     | jq -r '.org     // "N/A"')"

    echo "IPv4:     ${v4:-N/A}"
    echo "IPv6:     ${v6:-N/A}"
    echo "Location: $city, $region, $country"
    echo "ISP:      $org"
}

alias localip='ip -br addr show | grep -v lo'

# --- Bluetooth shortcuts ---
alias blon='bluetoothctl power on'
alias bloff='bluetoothctl power off'

# --- Screen shortcut ---
sco() {
    if [[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
        sleep 1 && hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })'
    else
        dbus-send --session --print-reply --dest=org.kde.kglobalaccel /component/org_kde_powerdevil org.kde.kglobalaccel.Component.invokeShortcut string:'Turn Off Screen'
    fi
}

cleanpkgs() {
    sudo pacman -Rns ${(f)"$(pacman -Qdtq)"}
    sudo paccache -rk2
    sudo paccache -ruk0
}

cleanup() {
    echo "🗑️ Emptying Root Trash..."
    sudo find /root/.local/share/Trash -mindepth 1 -delete 2>/dev/null

    echo "🗑️ Emptying User Trash..."
    find ~/.local/share/Trash/files -mindepth 1 -delete 2>/dev/null

    echo "📦 Cleaning unused Flatpaks..."
    flatpak uninstall --unused -y

    if command -v pnpm &>/dev/null; then
        echo "🌐 Pruning pnpm store..."
        pnpm store prune
    else
        echo "⚠️ pnpm not found or not in PATH, skipping..."
    fi

    echo "🧹 Checking for orphaned pacman packages..."
    local orphans=(${(f)"$(pacman -Qdtq)"})
    if (( ${#orphans[@]} )); then
        sudo pacman -Rns "${orphans[@]}"
    else
        echo "✅ No orphaned packages to remove."
    fi

    echo "🗄️ Cleaning pacman cache..."
    sudo paccache -rk2
    sudo paccache -ruk0

    echo "🎉 System cleanup complete!"
}

alias updt="sudo pacman -Syu"

sysmaint() {
    local ans _nw_iface _nw_ipfile _nw_lblfile _nw_pid

    # --- Start network capture in background (parallel to all maintenance) ---
    _nw_ipfile=$(mktemp /tmp/sysmaint_nw_ip.XXXXXX)
    _nw_lblfile=$(mktemp /tmp/sysmaint_nw_lbl.XXXXXX)
    if ip link show atvpn &>/dev/null; then
        _nw_iface="atvpn"
    else
        echo "==> [netwatch] atvpn not found, falling back to default interface"
        _nw_iface="$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')"
    fi
    (
        tshark -i "$_nw_iface" -l -q \
            -T fields -e ip.dst -e ip.dst_host -e http.host \
            -e tls.handshake.extensions_server_name -N n \
            2>/dev/null | \
        while IFS=$'\t' read -r _ip _dns _http _sni; do
            _ip="${_ip%%,*}"
            [[ -z "$_ip" ]] && continue
            echo "$_ip" >> "$_nw_ipfile"
            if   [[ -n "$_sni"  && "$_sni"  != "$_ip" ]]; then _lbl="$_sni"
            elif [[ -n "$_http" && "$_http" != "$_ip" ]]; then _lbl="$_http"
            elif [[ -n "$_dns"  && "$_dns"  != "$_ip" ]]; then _lbl="$_dns"
            else continue
            fi
            printf '%s\t%s\n' "$_ip" "$_lbl" >> "$_nw_lblfile"
        done
    ) &
    _nw_pid=$!

    echo "==> Running pacman -Syu..."
    sudo pacman -Syu || {
        echo "pacman -Syu failed." >&2
        kill "$_nw_pid" 2>/dev/null
        rm -f "$_nw_ipfile" "$_nw_lblfile"
        return 1
    }

    echo "==> Updating package list..."
    updtpkglist

    echo "==> Cleaning orphaned packages and cache..."
    cleanpkgs

    echo "==> Pushing dotfiles..."
    pushdots

    echo "==> Running yay -Syu..."
    yay -Syu

    # Local backup: autodetect — run only if SSD is mounted, no prompt
    if [[ -d "$SSD_MOUNT" ]]; then
        echo "==> Local SSD detected, running contentbak..."
        contentbak
    else
        echo "==> Local SSD not mounted ($SSD_MOUNT), skipping local backup."
    fi

    read "ans?Run contentbak -g (Google Drive backup)? [y/N] "
    if [[ "$ans" == [Yy] ]]; then
        contentbak -g
    fi

    echo "==> Running downloads organizer..."
    python3 /home/richard/dotfiles/scripts/downloads_organizer.py

    echo "==> Running music manager..."
    music_manager ~/Music

    # --- Stop capture and print network summary ---
    kill "$_nw_pid" 2>/dev/null
    wait "$_nw_pid" 2>/dev/null

    echo ""
    echo "==> Network traffic summary (excluding local IPs):"
    if [[ -s "$_nw_ipfile" ]]; then
        printf '\033[1m%-7s  %-22s  %s\033[0m\n' "PACKETS" "DESTINATION IP" "HOST / LABEL"
        printf '─%.0s' {1..60}; echo ""
        awk -F'\t' -v lbl="$_nw_lblfile" '
            BEGIN { while ((getline line < lbl) > 0) {
                split(line, a, "\t"); cache[a[1]] = a[2]
            }}
            {
                ip = $1
                if (ip ~ /^10\./ || ip ~ /^127\./ || ip ~ /^169\.254\./ ||
                    ip ~ /^192\.168\./) next
                if (ip ~ /^172\./) {
                    n = split(ip, o, ".")
                    if (n >= 2 && o[2]+0 >= 16 && o[2]+0 <= 31) next
                }
                count[ip]++
            }
            END {
                for (ip in count) {
                    label = (ip in cache) ? cache[ip] : ip
                    printf "%d\t%s\t%s\n", count[ip], ip, label
                }
            }
        ' "$_nw_ipfile" | sort -rn | while IFS=$'\t' read -r cnt ip lbl; do
            printf '%-7s  %-22s  %s\n' "$cnt" "$ip" "$lbl"
        done
    else
        echo "  (no traffic recorded)"
    fi

    rm -f "$_nw_ipfile" "$_nw_lblfile"

    echo ""
    echo "==> sysmaint done."
    fastfetch
}

updtpkglist() {
    pacman -Qqe > ~/dotfiles/pkglist.txt
    cd ~/dotfiles && git add pkglist.txt
    cd -
}

pushdots() {
    local msg="${1:-update dotfiles}"
    updtpkglist
    cd ~/dotfiles && git add . && git commit -m "$msg" && git push
    cd -
}

# Go up N directories
up() {
    local n="${1:-1}"
    repeat "$n"; do cd ..; done
}

# Locate in custom DBs
ff() {
    plocate -d ~/.documents.db:~/.downloads.db "$@"
}

# Copy a file's contents, or a command's output, to the clipboard
copy() {
    command -v wl-copy &>/dev/null || { echo "wl-copy not found" >&2; return 1; }
    if [[ -f "$1" ]]; then
        wl-copy < "$1"
    else
        eval "$@" | wl-copy
    fi
}

# Copy the last command run
copylast() {
    fc -ln -1 | sed 's/^[[:space:]]*//' | wl-copy
}

# Universal extract
extract() {
    local into_folder=false
    local file=""
    local arg
    for arg in "$@"; do
        case "$arg" in
            -f) into_folder=true ;;
            *)  file="$arg" ;;
        esac
    done

    if [[ -z "$file" ]]; then
        echo "Usage: extract [-f] <file>"
        return 1
    fi

    if [[ ! -e "$file" ]]; then
        echo "File not found: $file"
        return 1
    fi

    if [[ "$into_folder" == true ]]; then
        local folder="$(basename "$file" | sed -E 's/\.(tar\.(gz|bz2|xz)|tgz|zip|gz|7z)$//')"
        mkdir -p "$folder"
        case "$file" in
            *.tar.gz|*.tgz) tar xzf "$file" -C "$folder" ;;
            *.tar.bz2)      tar xjf "$file" -C "$folder" ;;
            *.tar.xz)       tar xJf "$file" -C "$folder" ;;
            *.zip)          unzip "$file" -d "$folder" ;;
            *.gz)           cp "$file" "$folder/" && gunzip "$folder/$(basename "$file")" ;;
            *.7z)           7z x "$file" -o"$folder" ;;
            *)              echo "Unknown format: $file"; return 1 ;;
        esac
        echo "Extracted into ./$folder/"
    else
        case "$file" in
            *.tar.gz|*.tgz) tar xzf "$file" ;;
            *.tar.bz2)      tar xjf "$file" ;;
            *.tar.xz)       tar xJf "$file" ;;
            *.zip)          unzip "$file" ;;
            *.gz)           gunzip "$file" ;;
            *.7z)           7z x "$file" ;;
            *)              echo "Unknown format: $file"; return 1 ;;
        esac
    fi
}

# Archive a directory (or cwd) into a dated tar.gz
archive() {
    local target outname
    if (( $# > 0 )); then
        target="$1"
        outname="$(basename "$1")"
    else
        target="$PWD"
        outname="$(basename "$PWD")"
    fi

    local filecount="$(find "$target" -type f | wc -l)"
    if (( filecount > 20 )); then
        local confirm
        read "confirm?Warning: $filecount files found in '$target'. Continue? [y/N] "
        if [[ "$confirm" != [Yy] ]]; then
            echo "Aborted."
            return 1
        fi
    fi

    local outfile="${outname}_$(date +%Y%m%d).tar.gz"
    local tmpfile="/tmp/$outfile"

    tar czf "$tmpfile" -C "$target" --transform 's|^\./||' .
    mv "$tmpfile" "$outfile"
    echo "Archived $filecount files → $outfile"
}

# --- vpn ---
alias wuvpnon="sudo openconnect --protocol=gp -b vpn.wu.ac.at"
alias wuvpnoff="sudo pkill openconnect"

vpnon() {
    local flag="$1"
    local conf=""
    local pf=false

    case "$flag" in
        -a)   conf="atvpn" ;;
        -apf) conf="atvpn_pf"; pf=true ;;
        -h)   conf="huvpn" ;;
        -hpf) conf="huvpn_pf"; pf=true ;;
        *)
            echo "Usage: vpnon [-a|-apf|-h|-hpf]"
            echo "  -a    Austria VPN"
            echo "  -apf  Austria VPN with port forwarding"
            echo "  -h    Hungary VPN"
            echo "  -hpf  Hungary VPN with port forwarding"
            return 1
            ;;
    esac

    echo "Connecting to $conf..."
    sudo systemctl start wg-quick@$conf || { echo "Failed to connect to $conf." >&2; return 1; }
    echo "Connected to $conf."
    if [[ "$pf" == true ]]; then
        echo "Public port: $(getpport)"
    fi
    sleep 3 && myip
}

vpnoff() {
    local active=()
    local svc
    for svc in atvpn atvpn_pf huvpn huvpn_pf; do
        if systemctl is-active --quiet wg-quick@$svc 2>/dev/null; then
            active+=($svc)
        fi
    done

    if (( ${#active[@]} == 0 )); then
        echo "No WireGuard VPN is active."
        return 0
    fi

    for svc in "${active[@]}"; do
        echo "Disconnecting $svc..."
        sudo systemctl stop wg-quick@$svc
    done
    sleep 3 && myip
}

editvpn() {
    local flag="$1"
    local conf=""

    case "$flag" in
        -a)   conf="atvpn" ;;
        -apf) conf="atvpn_pf" ;;
        -h)   conf="huvpn" ;;
        -hpf) conf="huvpn_pf" ;;
        *)
            echo "Usage: editvpn [-a|-apf|-h|-hpf]"
            echo "  -a    Austria VPN"
            echo "  -apf  Austria VPN with port forwarding"
            echo "  -h    Hungary VPN"
            echo "  -hpf  Hungary VPN with port forwarding"
            return 1
            ;;
    esac

    sudo nano /etc/wireguard/$conf.conf
}

# Display current public NAT-PMP port (requires an active pf VPN connection)
getpport() {
    local port="$(natpmpc -a 1 0 tcp 60 -g 10.2.0.1 2>/dev/null \
        | grep -oP 'Mapped public port \K[0-9]+' \
        | head -n1)"

    if [[ -n "$port" ]]; then
        echo "$port"
    else
        echo "Failed to get public port" >&2
        return 1
    fi
}

# --- Misc ---
alias weather='curl wttr.in'

toppct() {
    local include_hidden=false
    local dir=""
    local arg
    for arg in "$@"; do
        if [[ "$arg" == "-a" ]]; then
            include_hidden=true
        else
            dir="$arg"
        fi
    done

    [[ -z "$dir" ]] && dir="$PWD"

    if [[ "$include_hidden" == true ]]; then
        find "$dir" -type f -print0 | xargs -0 du -b | sort -rn | awk '
        BEGIN { top5=0; top10=0; total=0; count=0 }
        { size[count]=$1; total+=$1; count++ }
        END {
            for(i=0;i<count;i++) {
                if(i<5) top5+=size[i]
                if(i<10) top10+=size[i]
            }
            printf "Top 5  files: %.1f%% of total\n", (top5/total)*100
            printf "Top 10 files: %.1f%% of total\n", (top10/total)*100
        }'
    else
        find "$dir" -type f -not -path '*/.*' -print0 | xargs -0 du -b | sort -rn | awk '
        BEGIN { top5=0; top10=0; total=0; count=0 }
        { size[count]=$1; total+=$1; count++ }
        END {
            for(i=0;i<count;i++) {
                if(i<5) top5+=size[i]
                if(i<10) top10+=size[i]
            }
            printf "Top 5  files: %.1f%% of total\n", (top5/total)*100
            printf "Top 10 files: %.1f%% of total\n", (top10/total)*100
        }'
    fi
}

alias largestls='ls -lhS'

# --- KDE Plasma usage stats ---
alias plasma-counts="sqlite3 ~/.local/share/kactivitymanagerd/resources/database \
    \"SELECT initiatingAgent, COUNT(*) as launch_count \
    FROM ResourceEvent \
    WHERE initiatingAgent NOT LIKE 'org.kde.plasma%' \
    AND initiatingAgent NOT LIKE 'org.kde.libtaskmanager' \
    AND initiatingAgent NOT LIKE 'org.kde.krunner' \
    AND initiatingAgent NOT LIKE '%desktop-portal%' \
    GROUP BY initiatingAgent ORDER BY launch_count DESC;\""

alias plasma-scores="sqlite3 ~/.local/share/kactivitymanagerd/resources/database \
    \"SELECT initiatingAgent, targettedResource, cachedScore \
    FROM ResourceScoreCache \
    WHERE scoreType = 0 \
    AND initiatingAgent NOT LIKE 'org.kde.plasma%' \
    AND initiatingAgent NOT LIKE 'org.kde.libtaskmanager' \
    AND initiatingAgent NOT LIKE 'org.kde.krunner' \
    AND initiatingAgent NOT LIKE '%desktop-portal%' \
    ORDER BY cachedScore DESC LIMIT 15;\""
