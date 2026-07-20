
# ============================================================
#  Personal zsh config
# ============================================================



# Build nix, TODO
alias nixbs="sudo nixos-rebuild switch --flake ~/dotfiles/nix-config#nixos && pushdots"

# --- Boot time stats ---
alias bootstats='python3 ~/dotfiles/scripts/bootstats'

# --- Quickshell ---
alias qsrestart='pkill -9 -x quickshell 2>/dev/null; pkill quickshell 2>/dev/null; sleep 0.5; qs -c ii &'

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


alias wifirec="nmcli radio wifi off && nmcli radio wifi on"
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
alias zshpwd="echo ~/dotfiles/.zshrc"
alias zshcopy="copy ~/dotfiles/.zshrc"
alias sourcezsh='source ~/dotfiles/.zshrc'
alias zshconfig='nano ~/dotfiles/.zshrc'
alias htopcopy="copy 'ps auxf'"

zshcfgsrc() {
  if [[ "$1" == "-v" ]]; then
    nvim ~/dotfiles/.zshrc
  elif [[ "$1" == "-k" ]]; then
    kate ~/dotfiles/.zshrc
  else
    nano ~/dotfiles/.zshrc
  fi
  source ~/dotfiles/.zshrc
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

# --- bitwarden vault password analyzer ---
pwanal() { python3 "$HOME/Documents/Projects/rbwcheck/pwanal.py" "$@"; }

export PATH="$HOME/dotfiles/scripts:$HOME/Documents/Projects/rbwcheck:$PATH"
[[ -f ~/.zshrc.secrets ]] && source ~/.zshrc.secrets
# encryption
# deprecated: vault deleted 2026-07-11, data already moved out. future use TBD, keeping aliases around just in case.
alias ecvault="fusermount3 -u ~/Documents/Vault"
alias dcvault="gocryptfs ~/.vault-encrypted ~/Documents/Vault && obsidian"

# Password-protect a file/folder into a .7z, or decrypt one back.
# Also supports adding/removing individual files in an existing archive:
#   pw7z -a folder.7z randomfile.txt   # add file(s) into the archive
#   pw7z -r folder.7z randomfile.txt   # remove file(s) from the archive
# (this build of 7z echoes its own password prompt in cleartext, so we
# read the password ourselves with hidden input and hand it to 7z directly)
pw7z() {
    if [[ "$1" == "-a" || "$1" == "-r" ]]; then
        local op="$1" archive="$2"
        shift 2
        if [[ -z "$archive" || $# -eq 0 ]]; then
            echo "Usage: pw7z -a|-r <archive.7z> <file(s)...>" >&2
            return 1
        fi
        if [[ ! -f "$archive" ]]; then
            echo "pw7z: $archive: no such archive" >&2
            return 1
        fi
        if [[ "$op" == "-a" ]]; then
            local f
            for f in "$@"; do
                [[ -e "$f" ]] || { echo "pw7z: $f: no such file or directory" >&2; return 1; }
            done
        fi

        local password
        echo -n "Password for $archive: "
        read -rs password
        echo

        local rc
        if [[ "$op" == "-a" ]]; then
            7z a -p"$password" -mhe=on -bso0 -bsp0 -bd "$archive" "$@"
            rc=$?
        else
            7z d -p"$password" -bso0 -bsp0 -bd "$archive" "$@"
            rc=$?
        fi
        unset password
        (( rc != 0 )) && return $rc

        if [[ "$op" == "-a" ]]; then
            local reply
            for f in "$@"; do
                echo -n "Delete original unencrypted '$f'? [y/N] "
                read -r reply
                if [[ "$reply" =~ ^[Yy]$ ]]; then
                    rm -rf "$f"
                    echo "Deleted $f"
                else
                    echo "Kept $f"
                fi
            done
        else
            echo "Removed from $archive: $*"
        fi
        return 0
    fi

    local target="$1"
    if [[ -z "$target" ]]; then
        echo "Usage: pw7z <file_or_folder_or_archive.7z>" >&2
        return 1
    fi
    if [[ ! -e "$target" ]]; then
        echo "pw7z: $target: no such file or directory" >&2
        return 1
    fi

    local password reply
    if [[ "$target" == *.7z ]]; then
        echo -n "Password to decrypt: "
        read -rs password
        echo
    else
        # New password being set here, so confirm it to avoid a typo locking
        # you out of your own data.
        local password_confirm
        while true; do
            echo -n "Password to encrypt with: "
            read -rs password
            echo
            echo -n "Confirm password: "
            read -rs password_confirm
            echo
            [[ "$password" == "$password_confirm" ]] && break
            echo "pw7z: passwords do not match, try again" >&2
        done
        unset password_confirm
    fi

    if [[ "$target" == *.7z ]]; then
        # Decrypt: extract into the archive's directory (the archive already
        # contains the original folder name, so this restores it in place)
        local outdir="$(dirname -- "$target")"
        7z x -p"$password" -bso0 -bsp0 -bd "$target" -o"$outdir"
        local rc=$?
        unset password
        (( rc != 0 )) && return $rc
        echo -n "Delete original encrypted archive '$target'? [y/N] "
        read -r reply
        if [[ "$reply" =~ ^[Yy]$ ]]; then
            rm -f "$target"
            echo "Deleted $target"
        else
            echo "Kept $target"
        fi
    else
        # Encrypt: create a password-protected .7z (names + contents encrypted)
        local archive="${target%/}.7z"
        7z a -p"$password" -mhe=on -bso0 -bsp0 -bd "$archive" "$target"
        local rc=$?
        unset password
        (( rc != 0 )) && return $rc
        echo -n "Delete original unencrypted '$target'? [y/N] "
        read -r reply
        if [[ "$reply" =~ ^[Yy]$ ]]; then
            rm -rf "$target"
            echo "Deleted $target"
        else
            echo "Kept $target"
        fi
    fi
}

# --- Directory shortcuts ---
SSD_MOUNT="/run/media/$USER/7ABF-7932"
alias ssd='cd "$SSD_MOUNT"'
alias richard="cd $HOME"
alias thesis="cd $HOME/Documents/Thesis"
alias config='cd ~/.config'
alias kdeconf='cd ~/.config'
alias ddls="cd $HOME/Downloads"
alias docs="cd $HOME/Documents"
alias dotf="cd $HOME/dotfiles"

# --- System shortcuts ---
alias syslog='journalctl -f'
alias slep='systemctl suspend'

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

# backup commands
alias pdrivebackup="rclone copy /home/richard/Documents/docs pdrive:backup/docs --protondrive-replace-existing-draft=true -P"
alias gdrivebackup="rclone copy /run/media/richard/7ABF-7932/backup/restic_repo gdrive:backup/restic_repo --progress --transfers 4 --checkers 8 --retries 10 --low-level-retries 20 --timeout 5m --contimeout 1m --stats 5s"


# Backup using restic to local SSD
# Repo: $SSD_MOUNT/backup/restic_repo
# Retention: 7 daily, 4 weekly, 6 monthly snapshots kept after each run.
contentbak() {
    local repo="$SSD_MOUNT/backup/restic_repo"
    mountpoint -q "$SSD_MOUNT" || { echo "Drive not mounted at $SSD_MOUNT." >&2; return 1; }

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

    # Init repo on first use (check for the config object directly — no
    # password needed — instead of asking restic, whose password prompt
    # goes to stderr and was getting swallowed by a stray redirect here)
    local repo_exists=false
    [[ -f "$repo/config" ]] && repo_exists=true
    if [[ "$repo_exists" == false ]]; then
        echo "Initializing restic repo at $repo..."
        restic -r "$repo" init || return 1
    fi

    echo "Backing up to $repo..."
    restic -r "$repo" backup --verbose "${excludes[@]}" "${sources[@]}" || return 1

    echo "Pruning old snapshots..."
    restic -r "$repo" forget --keep-last 10 --prune

    echo "Done → $repo"
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


nixcleanup() {
    echo "==> Deleting generations older than 7 days..."
    sudo nix-collect-garbage --delete-older-than 7d
    echo "==> Running store GC..."
    nix store gc
    echo "==> Optimising store..."
    nix store optimise
    echo "==> Done."
}

pushdots() {
    local msg="${1:-update dotfiles}"
    cd ~/dotfiles
    # Untrack anything that's become a home-manager symlink before staging
    find . -type l -lname '/nix/store/*' -exec git rm --cached {} \; 2>/dev/null
    git add . && git commit -m "$msg" && git push
    cd -
}

# Go up N directories
up() {
    local n="${1:-1}"
    repeat "$n"; do cd ..; done
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
    local flag="${1:--a}"
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

    local active_vpn
    for active_vpn in atvpn atvpn_pf huvpn huvpn_pf; do
        if systemctl is-active --quiet wg-quick-$active_vpn 2>/dev/null; then
            echo "Already connected to $active_vpn. Run vpnoff first." >&2
            return 1
        fi
    done

    echo "Connecting to $conf..."
    sudo systemctl start wg-quick-$conf || { echo "Failed to connect to $conf." >&2; return 1; }
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
        if systemctl is-active --quiet wg-quick-$svc 2>/dev/null; then
            active+=($svc)
        fi
    done

    if (( ${#active[@]} == 0 )); then
        echo "No WireGuard VPN is active."
        return 0
    fi

    for svc in "${active[@]}"; do
        echo "Disconnecting $svc..."
        sudo systemctl stop wg-quick-$svc
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
[ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ] && . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
