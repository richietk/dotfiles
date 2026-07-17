{ config, pkgs, ... }:
{
  home.username = "richard";
  home.homeDirectory = "/home/richard";
  home.stateVersion = "24.05";
  targets.genericLinux.enable = true;

  home.packages = with pkgs; [
    ripgrep
    fastfetch
    btop
    eza
    zoxide
    fzf
    jq
    ncdu
    yazi
    cowsay
    cmatrix
    yt-dlp
    translate-shell
    tree
    wget
    rclone
    htop
    rsync
    speedtest-cli
    sysstat
    unzip
    unrar
    github-cli
    yq-go
    python3
    uv
    libreoffice-still
    pnpm
    plocate
    nixfmt
    kitty
    bc
    curl
    less
    mc
    nnn
    file-rename
    pyright
    strace
    testdisk
    tesseract
    fdupes
    graphviz
    imagemagick
    inxi
  hyprlock
  hypridle
  hyprpaper
  wlogout
  fuzzel
  grim
  slurp
  wf-recorder
quickshell
kdePackages.qt5compat
kdePackages.qtpositioning
claude-code
doublecmd
restic
git
libnatpmp
qview
mpv
wl-clipboard
rbw
pinentry-qt
  ];

programs.zsh = {
  enable = true;
  enableCompletion = true;
  autosuggestion.enable = true;
  syntaxHighlighting.enable = true;
  oh-my-zsh = {
    enable = true;
    theme = "robbyrussell";
    plugins = [ "git" ];
  };
  initContent = ''
    [ -f ~/dotfiles/.zshrc ] && source ~/dotfiles/.zshrc
  '';
};

xdg.mimeApps = {
  enable = true;
  defaultApplications = {
    "image/jpeg"    = "qview.desktop";
    "image/png"     = "qview.desktop";
    "image/gif"     = "qview.desktop";
    "image/webp"    = "qview.desktop";
    "image/bmp"     = "qview.desktop";
    "image/tiff"    = "qview.desktop";
    "image/svg+xml" = "qview.desktop";
    "image/x-icon"  = "qview.desktop";
    "video/mp4"             = "mpv.desktop";
    "video/x-matroska"      = "mpv.desktop";
    "video/webm"            = "mpv.desktop";
    "video/avi"             = "mpv.desktop";
    "video/quicktime"       = "mpv.desktop";
    "video/x-msvideo"       = "mpv.desktop";
    "video/mpeg"            = "mpv.desktop";
    "video/ogg"             = "mpv.desktop";
    "video/x-flv"           = "mpv.desktop";
    "video/3gpp"            = "mpv.desktop";
  };
};

xdg.configFile."mimeapps.list".force = true;

home.file.".config/rbw/config.json".text = builtins.toJSON {
  email                 = "takacs.richard121@gmail.com";
  sso_id                = null;
  base_url              = "https://api.bitwarden.eu";
  identity_url          = "https://identity.bitwarden.eu";
  ui_url                = "https://vault.bitwarden.eu";
  notifications_url     = "https://notifications.bitwarden.eu";
  lock_timeout          = 3600;
  sync_interval         = 3600;
  pinentry              = "pinentry";
  client_cert_path      = null;
};

home.file.".config/kitty/kitty.conf".source =
  config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/kitty/kitty.conf";

home.file.".config/hypr".source =
  config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/hypr";

home.file.".config/quickshell".source =
  config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/quickshell";

}
