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
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initContent = ''
      [ -f ~/dotfiles/.zshrc ] && source ~/dotfiles/.zshrc
    '';
  };

programs.starship = {
  enable = true;
};

home.file.".config/kitty/kitty.conf".source =
  config.lib.file.mkOutOfStoreSymlink "/home/richard/dotfiles/.config/kitty/kitty.conf";

  programs.home-manager.enable = true;
}
