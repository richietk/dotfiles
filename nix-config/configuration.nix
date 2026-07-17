# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = "systemd-resolved";
  services.resolved.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Vienna";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_AT.UTF-8";
    LC_IDENTIFICATION = "de_AT.UTF-8";
    LC_MEASUREMENT = "de_AT.UTF-8";
    LC_MONETARY = "de_AT.UTF-8";
    LC_NAME = "de_AT.UTF-8";
    LC_NUMERIC = "de_AT.UTF-8";
    LC_PAPER = "de_AT.UTF-8";
    LC_TELEPHONE = "de_AT.UTF-8";
    LC_TIME = "de_AT.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

services.power-profiles-daemon.enable = false; # conflicts with TLP; KDE enables this by default
services.tlp.enable = true;

services.asusd.enable = true;

systemd.tmpfiles.rules = [
  "d /etc/asusd 0755 root root -"
];
  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "hu";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "hu";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."richard" = {
    isNormalUser = true;
    description = "richard";
    extraGroups = [ "networkmanager" "wheel" ];
shell = pkgs.zsh;
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # add hyprland
  programs.hyprland.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
  wireguard-tools
  ffmpeg
  ];

  networking.wg-quick.interfaces = {
    atvpn = { autostart = true; configFile = "/etc/wireguard/atvpn.conf"; };
    atvpn_pf = { autostart = false; configFile = "/etc/wireguard/atvpn_pf.conf"; };
    huvpn = { autostart = false; configFile = "/etc/wireguard/huvpn.conf"; };
    huvpn_pf = { autostart = false; configFile = "/etc/wireguard/huvpn_pf.conf"; };
  };

 fonts.packages = with pkgs; [
  material-symbols
  nerd-fonts.jetbrains-mono
];


hardware.bluetooth.enable = true;
hardware.bluetooth.powerOnBoot = true;
services.blueman.enable = true;

hardware.bluetooth.settings = {
  General = {
    Experimental = true;
  };
};

  programs.zsh.enable = true;


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?

 # nixpkgs
 nix.settings.experimental-features = [ "nix-command" "flakes" ];
 nix.settings.http2 = false;

 boot.kernel.sysctl."net.ipv4.tcp_mtu_probing" = 1;

  systemd.services.thermal-guard = {
    description = "Thermal-based CPU frequency guard";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "5s";
      ExecStart = pkgs.writeShellScript "thermal-guard" ''
        # Discover k10temp hwmon path dynamically — the index can shift between boots
        TEMP_INPUT=""
        for dir in /sys/class/hwmon/hwmon*; do
          if [ "$(cat "$dir/name" 2>/dev/null)" = "k10temp" ]; then
            TEMP_INPUT="$dir/temp1_input"
            break
          fi
        done
        if [ -z "$TEMP_INPUT" ]; then
          echo "k10temp hwmon device not found, exiting" >&2
          exit 1
        fi
        echo "Monitoring CPU temperature at $TEMP_INPUT"

        MAX_FREQ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)
        THROTTLE_FREQ=2000000  # 2 GHz cap when hot
        THROTTLE_TEMP=85000    # millidegrees
        RESTORE_TEMP=75000     # millidegrees (hysteresis)
        THROTTLED=0

        set_max_freq() {
          for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
            echo "$1" > "$f"
          done
        }

        while true; do
          TEMP=$(cat "$TEMP_INPUT" 2>/dev/null) || { sleep 5; continue; }
          if [ "$THROTTLED" -eq 0 ] && [ "$TEMP" -ge "$THROTTLE_TEMP" ]; then
            echo "CPU hot ($(( TEMP / 1000 ))°C), throttling to 2 GHz"
            set_max_freq "$THROTTLE_FREQ"
            THROTTLED=1
          elif [ "$THROTTLED" -eq 1 ] && [ "$TEMP" -lt "$RESTORE_TEMP" ]; then
            echo "CPU cooled ($(( TEMP / 1000 ))°C), restoring max frequency"
            set_max_freq "$MAX_FREQ"
            THROTTLED=0
          fi
          sleep 5
        done
      '';
    };
  };

}
