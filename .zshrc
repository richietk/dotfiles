# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"



# ============================================================
#  Personal zsh config — translated from config.fish
#  Paste everything below into ~/.zshrc, AFTER the line
#  `source $ZSH/oh-my-zsh.sh` so nothing gets overridden.
# ============================================================

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
alias sourcez='source ~/.zshrc'
alias zshconfig='nano ~/.zshrc'
alias htopcopy="copy 'ps auxf'"

zshcfgsrc() {
  if [[ "$1" == "-v" ]]; then
    nvim ~/.zshrc
  else
    nano ~/.zshrc
  fi
  source ~/.zshrc
}


# --- Virtual environment shortcuts ---
alias venvact='source ~/venv/bin/activate'
alias venvdeact='deactivate 2>/dev/null || true'

# --- irq balance checker ---
irqgini() {
    python3 -c "
import re

with open('/proc/interrupts') as f:
    lines = f.readlines()

n_cpus = len(lines[0].split())
counts = [0] * n_cpus

for line in lines[1:]:
    if re.search('nvme', line, re.IGNORECASE):
        parts = line.split()
        for i in range(n_cpus):
            try:
                counts[i] += int(parts[i + 1])
            except (IndexError, ValueError):
                pass

total = sum(counts)
if not total:
    print('No NVMe interrupts counted')
    exit(1)

shares = sorted([c / total for c in counts], reverse=True)
n = len(shares)
s = sorted(shares)
gini = 1 - 2 * sum((n - i) * x for i, x in enumerate(s)) / (n * sum(s))

print(f'Total NVMe interrupts : {total:,}')
print(f'CPUs                  : {n}')
print(f'Top 1 core share      : {shares[0]*100:.1f}%')
print(f'Top 2 cores share     : {sum(shares[:2])*100:.1f}%')
print(f'Top 4 cores share     : {sum(shares[:4])*100:.1f}%')
print(f'Gini                  : {gini:.3f}  (0=even, 1=one core takes all)')
"
}

# --- Directory shortcuts ---
alias ssd='cd /mnt/ssd'
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

# Backup to external drive
contentbak() {
    local pack=false
    local arg
    for arg in "$@"; do
        [[ "$arg" == "-p" ]] && pack=true
    done

    local datestr="$(date +%Y%m%d)"
    local dest="/run/media/richard/7ABF-7932/backup/content_backups/content_bak_$datestr"
    if [[ ! -d /run/media/richard/7ABF-7932 ]]; then
        echo "Drive not mounted."
        return 1
    fi
    mkdir -p "$dest"

    local dirs=(
        $HOME/.config
        $HOME/Desktop
        $HOME/Documents
        $HOME/Downloads
        $HOME/Music
        $HOME/Pictures
        $HOME/Videos
    )

    if [[ "$pack" == true ]]; then
        local tmpfile="/tmp/content_bak_$datestr.tar.gz"
        echo "Packing everything into a single archive..."
        tar czf "$tmpfile" \
            --exclude="$HOME/.config/google-chrome" \
            --exclude="$HOME/.config/discord" \
            --exclude="$HOME/.config/mozilla" \
            --exclude="$HOME/.config/Code" \
            --exclude="$HOME/.config/libreoffice" \
            --exclude="$HOME/.config/.venv" \
            --exclude='*.lock' \
            "${dirs[@]}"
        mv "$tmpfile" "$dest/"
        echo "Done → $dest/content_bak_$datestr.tar.gz"
    else
        local dir
        for dir in "${dirs[@]}"; do
            echo "Copying $(basename "$dir")..."
            if [[ "$dir" == $HOME/.config ]]; then
                rsync -rpt \
                    --no-links \
                    --ignore-errors \
                    --update \
                    --exclude='*.lock' \
                    --exclude='google-chrome/' \
                    --exclude='discord/' \
                    --exclude='mozilla/' \
                    --exclude='Code/' \
                    --exclude='.venv/' \
                    --exclude='libreoffice/' \
                    --info=progress2 \
                    "$dir" "$dest/"
            else
                rsync -rpt \
                    --no-links \
                    --ignore-errors \
                    --update \
                    --exclude='*.lock' \
                    --info=progress2 \
                    "$dir" "$dest/"
            fi
        done
        echo "Done → $dest"
    fi
}

# Backup to Google Drive via rclone
contentbak_gdrive() {
    local pack=false
    local arg
    for arg in "$@"; do
        [[ "$arg" == "-p" ]] && pack=true
    done

    local remote="gdrive"
    local date_str="$(date +%Y%m%d)"
    local dest="${remote}:backup/content_backups/content_bak_${date_str}"
    local tmpdir="/tmp/contentbak_${date_str}"

    if ! command -v rclone &>/dev/null; then
        echo "rclone not installed."
        return 1
    fi
    if ! rclone listremotes | grep -q "^${remote}:"; then
        echo "rclone remote '$remote' not configured. Run: rclone config"
        return 1
    fi

    mkdir -p "$tmpdir"

    local dirs=(
        $HOME/.config
        $HOME/Desktop
        $HOME/Documents
        $HOME/Downloads
        $HOME/Music
        $HOME/Pictures
        $HOME/Videos
    )

    if [[ "$pack" == true ]]; then
        local tmpfile="$tmpdir/content_bak_${date_str}.tar.gz"
        echo "Packing everything into a single archive..."
        tar czf "$tmpfile" \
            --exclude="$HOME/.config/google-chrome" \
            --exclude="$HOME/.config/discord" \
            --exclude="$HOME/.config/mozilla" \
            --exclude="$HOME/.config/Code" \
            --exclude="$HOME/.config/libreoffice" \
            --exclude="$HOME/.config/.venv" \
            --exclude='*.lock' \
            "${dirs[@]}"
        echo "Uploading single archive..."
        rclone copy \
            --transfers=16 --checkers=32 --drive-chunk-size=64M \
            --progress \
            "$tmpfile" "$dest/"
    else
        echo "Archiving .config..."
        tar czf "$tmpdir/config.tar.gz" \
            --exclude="$HOME/.config/google-chrome" \
            --exclude="$HOME/.config/discord" \
            --exclude="$HOME/.config/mozilla" \
            --exclude="$HOME/.config/Code" \
            --exclude="$HOME/.config/libreoffice" \
            --exclude='*.lock' \
            $HOME/.config
        echo "Uploading .config.tar.gz..."
        rclone copy \
            --transfers=16 --checkers=32 --drive-chunk-size=64M \
            --progress \
            "$tmpdir/config.tar.gz" "$dest/"

        local dir
        for dir in $dirs[2,-1]; do      # everything except .config (1-indexed slice)
            echo "Uploading $(basename "$dir")..."
            rclone copy \
                --links=false \
                --ignore-errors \
                --update \
                --exclude='*.lock' \
                --exclude='.venv/' \
                --transfers=16 \
                --checkers=32 \
                --drive-chunk-size=64M \
                --progress \
                "$dir" "$dest/$(basename "$dir")/"
        done
    fi

    rm -rf "$tmpdir"
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
alias sco="dbus-send --session --print-reply --dest=org.kde.kglobalaccel /component/org_kde_powerdevil org.kde.kglobalaccel.Component.invokeShortcut string:'Turn Off Screen'"

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
alias vpnoff="sudo systemctl stop wg-quick@atvpn"
alias vpnon="sudo systemctl start wg-quick@atvpn"
alias vpnpfoff="sudo systemctl stop wg-quick@atvpn_pf"
alias vpnpfon="sudo systemctl start wg-quick@atvpn_pf"
alias wuvpnon="sudo openconnect --protocol=gp -b vpn.wu.ac.at"
alias wuvpnoff="sudo pkill openconnect"

# Display current public NAT-PMP port from vpnpfon
getpport() {
    sudo vpnpfon >/dev/null 2>&1

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
