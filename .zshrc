# ============================================================
#  Personal zsh config — loader
#  Actual config lives in ~/dotfiles/.config/zsh/*.zsh,
#  sourced in alphabetical order (numeric prefixes control it):
#    00-env         environment variables, PATH, secrets
#    10-aliases     all simple aliases
#    15-zsh-config  editing/reloading this config
#    20-functions   general helper functions
#    30-disks       mntdisk / unmntdisk
#    40-venv        python venv management
#    50-vpn         wireguard/openconnect helpers
#    60-encryption  pw7z, vault aliases
#    70-nix         nix generation rollback (rb)
#    90-plugins     zoxide etc. (keep last)
# ============================================================

for _zf in ~/dotfiles/.config/zsh/*.zsh; do
    source "$_zf"
done
unset _zf
