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
    uv
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
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = false;
    syntaxHighlighting.enable = false;
    initContent = ''
      [ -f ~/dotfiles/.zshrc ] && source ~/dotfiles/.zshrc
    '';
  };

home.file.".config/kitty/kitty.conf".source =
  config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/kitty/kitty.conf";

  programs.home-manager.enable = true;
}
