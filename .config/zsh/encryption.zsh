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
