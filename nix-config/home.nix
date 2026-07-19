{ config, pkgs, pkgs-unstable, ... }:
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
    pkgs-unstable.antigravity-cli
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
    just
    awatcher
    aw-server-rust
    neovim
  ];

  systemd.user.services.aw-server-rust = {
    Unit = {
      Description = "ActivityWatch server (Rust)";
      After = [ "default.target" ];
    };
    Install.WantedBy = [ "default.target" ];
    Service = {
      ExecStart = "${pkgs.aw-server-rust}/bin/aw-server";
      Restart = "on-failure";
    };
  };

  systemd.user.services.awatcher = {
    Unit = {
      Description = "awatcher activity tracker";
      After = [ "default.target" "aw-server-rust.service" ];
      Requires = [ "aw-server-rust.service" ];
    };
    Install.WantedBy = [ "default.target" ];
    Service = {
      ExecStart = "${pkgs.awatcher}/bin/awatcher";
      Restart = "on-failure";
    };
  };

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
      "image/jpeg"         = "qview.desktop";
      "image/png"          = "qview.desktop";
      "image/gif"          = "qview.desktop";
      "image/webp"         = "qview.desktop";
      "image/bmp"          = "qview.desktop";
      "image/tiff"         = "qview.desktop";
      "image/svg+xml"      = "qview.desktop";
      "image/x-icon"       = "qview.desktop";
      "video/mp4"          = "mpv.desktop";
      "video/x-matroska"   = "mpv.desktop";
      "video/webm"         = "mpv.desktop";
      "video/avi"          = "mpv.desktop";
      "video/quicktime"    = "mpv.desktop";
      "video/x-msvideo"    = "mpv.desktop";
      "video/mpeg"         = "mpv.desktop";
      "video/ogg"          = "mpv.desktop";
      "video/x-flv"        = "mpv.desktop";
      "video/3gpp"         = "mpv.desktop";
    };
  };
  xdg.configFile."mimeapps.list".force = true;

  home.file.".config/rbw/config.json".text = builtins.toJSON {
    email             = "takacs.richard121@gmail.com";
    sso_id            = null;
    base_url          = "https://api.bitwarden.eu";
    identity_url      = "https://identity.bitwarden.eu";
    ui_url            = "https://vault.bitwarden.eu";
    notifications_url = "https://notifications.bitwarden.eu";
    lock_timeout      = 3600;
    sync_interval     = 3600;
    pinentry          = "pinentry";
    client_cert_path  = null;
  };


  # --- Dotfile symlinks (all point back into ~/dotfiles for mutability) ---
  home.file.".gitconfig".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.gitconfig";

  home.file.".gtkrc-2.0".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.gtkrc-2.0";

  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.claude/settings.json";

  # Hyprland
  home.file.".config/hypr".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/hypr";

  # Kitty
  home.file.".config/kitty".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/kitty";

  # Quickshell
  home.file.".config/quickshell".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/quickshell";

  # Neovim
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/nvim";

  # mpv
  home.file.".config/mpv".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/mpv";

  # Fastfetch
  home.file.".config/fastfetch".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/fastfetch";

  # Fontconfig (only fonts.conf — home-manager owns conf.d/)
  home.file.".config/fontconfig/fonts.conf".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/fontconfig/fonts.conf";

  # Fuzzel
  home.file.".config/fuzzel".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/fuzzel";

  # wlogout
  home.file.".config/wlogout".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/wlogout";

  # cava
  home.file.".config/cava".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/cava";

  # btop
  home.file.".config/btop".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/btop";

  # Midnight Commander
  home.file.".config/mc".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/mc";

  # nnn
  home.file.".config/nnn".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/nnn";

  # KDiskMark
  home.file.".config/kdiskmark".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/kdiskmark";

  # Xournal++
  home.file.".config/xournalpp".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/xournalpp";

  # Kate (full dir: external tools, LSP config, etc.)
  home.file.".config/kate".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/kate";

  # KDE Plasma
  home.file.".config/kglobalshortcutsrc".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/kglobalshortcutsrc";

  home.file.".config/kwinrc".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/kwinrc";

  home.file.".config/kdeglobals".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/kdeglobals";

  home.file.".config/plasmashellrc".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/plasmashellrc";

  home.file.".config/plasma-org.kde.plasma.desktop-appletsrc".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/plasma-org.kde.plasma.desktop-appletsrc";

  home.file.".config/katerc".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/katerc";

  home.file.".config/katevirc".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/katevirc";

  home.file.".config/konsolerc".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/konsolerc";

  home.file.".config/kwriterc".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/kwriterc";

  # Kvantum
  home.file.".config/Kvantum/kvantum.kvconfig".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/Kvantum/kvantum.kvconfig";

  # GTK
  home.file.".config/gtk-3.0/settings.ini".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/gtk-3.0/settings.ini";

  home.file.".config/gtk-4.0/settings.ini".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/gtk-4.0/settings.ini";

  # Double Commander
  home.file.".config/doublecmd/doublecmd.xml".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/doublecmd/doublecmd.xml";

  home.file.".config/doublecmd/shortcuts.scf".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/doublecmd/shortcuts.scf";

  home.file.".config/doublecmd/colors.json".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/doublecmd/colors.json";

  home.file.".config/doublecmd/highlighters.xml".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/doublecmd/highlighters.xml";

  home.file.".config/doublecmd/multiarc.ini".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/doublecmd/multiarc.ini";

  programs.firefox = {
    enable = true;
    configPath = "${config.xdg.configHome}/mozilla/firefox";
    profiles.default = {
      settings = {
        "browser.startup.page"                                           = 3;
        "browser.newtabpage.activity-stream.feeds.topsites"             = false;
        "browser.newtabpage.activity-stream.newtabWallpapers.wallpaper" = "light-panda";
        "accessibility.typeaheadfind.flashBar"                          = 0;
        "toolkit.legacyUserProfileCustomizations.stylesheets"           = true;
      };
      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
        ublock-origin
        bitwarden
        absolute-enable-right-click
        # vimium was disabled in your old profile — uncomment to add it back:
        # vimium
        # linkclump is not in NUR — install it manually from addons.mozilla.org
      ];
    };
  };

  # DeadBeeF
  home.file.".config/deadbeef/config".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/deadbeef/config";

  home.file.".config/deadbeef/dspconfig".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/deadbeef/dspconfig";

  # beets
  home.file.".config/beets/config.yaml".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/beets/config.yaml";

  # OBS Studio
  home.file.".config/obs-studio/global.ini".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/obs-studio/global.ini";

  home.file.".config/obs-studio/user.ini".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/obs-studio/user.ini";

  home.file.".config/obs-studio/basic/profiles".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/obs-studio/basic/profiles";

  home.file.".config/obs-studio/basic/scenes".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/obs-studio/basic/scenes";

  # Wireshark
  home.file.".config/wireshark/extcap.cfg".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/wireshark/extcap.cfg";

  home.file.".config/wireshark/preferences".source =
    config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/wireshark/preferences";
}
