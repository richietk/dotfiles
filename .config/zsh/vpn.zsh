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

    sudo nvim /etc/wireguard/$conf.conf
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
