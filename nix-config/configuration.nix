{ config, pkgs, lib, agenix, ... }:

let
  touchpad-filter = pkgs.writers.writePython3Bin "touchpad-filter"
    { libraries = with pkgs.python3Packages; [ evdev ]; flakeIgnore = [ "E265" "E501" ]; }
    (builtins.readFile ../scripts/touchpad-filter);

  reset-touchpad = pkgs.writeShellScriptBin "reset-touchpad"
    (builtins.readFile ../scripts/reset-touchpad);

  sddm-sugar-candy = pkgs.stdenv.mkDerivation {
    name = "sddm-sugar-candy";
    src = ../system/sddm-themes;
    installPhase = ''
      mkdir -p $out/share/sddm/themes/sugar-candy
      cp -r . $out/share/sddm/themes/sugar-candy/
    '';
  };
in
{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernel.sysctl."net.ipv4.tcp_mtu_probing" = 1;
  boot.kernelParams = [ "reboot=efi" "amd_iommu=off" ];

  # Network
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = "systemd-resolved";
  services.resolved.enable = true;
  age.secrets."atvpn.conf"    = { file = ../secrets/atvpn.conf.age;    mode = "0600"; };
  age.secrets."atvpn_pf.conf" = { file = ../secrets/atvpn_pf.conf.age; mode = "0600"; };
  age.secrets."huvpn.conf"    = { file = ../secrets/huvpn.conf.age;     mode = "0600"; };
  age.secrets."huvpn_pf.conf" = { file = ../secrets/huvpn_pf.conf.age;  mode = "0600"; };

  networking.wg-quick.interfaces = {
    atvpn    = { autostart = true;  configFile = config.age.secrets."atvpn.conf".path; };
    atvpn_pf = { autostart = false; configFile = config.age.secrets."atvpn_pf.conf".path; };
    huvpn    = { autostart = false; configFile = config.age.secrets."huvpn.conf".path; };
    huvpn_pf = { autostart = false; configFile = config.age.secrets."huvpn_pf.conf".path; };
  };
 
services.openssh.enable=true;
  # Locale / timezone
  time.timeZone = "Europe/Vienna";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS        = "de_AT.UTF-8";
    LC_IDENTIFICATION = "de_AT.UTF-8";
    LC_MEASUREMENT    = "de_AT.UTF-8";
    LC_MONETARY       = "de_AT.UTF-8";
    LC_NAME           = "de_AT.UTF-8";
    LC_NUMERIC        = "de_AT.UTF-8";
    LC_PAPER          = "de_AT.UTF-8";
    LC_TELEPHONE      = "de_AT.UTF-8";
    LC_TIME           = "de_AT.UTF-8";
  };
  console.keyMap = "hu";

  # Desktop
  services.xserver.enable = true;
  services.xserver.xkb = { layout = "hu"; variant = ""; };
  # SDDM (sugar-candy) — kept for easy rollback, swap comments to re-enable
  # services.displayManager.sddm = {
  #   enable = true;
  #   theme = "sugar-candy";
  #   extraPackages = [ pkgs.kdePackages.qt5compat ];
  #   package = lib.mkForce (pkgs.kdePackages.sddm.override {
  #     sddm-unwrapped = pkgs.kdePackages.sddm.unwrapped.overrideAttrs (old: {
  #       postInstall = (old.postInstall or "") + ''
  #         ln -sf $out/bin/sddm-greeter-qt6 $out/bin/sddm-greeter
  #       '';
  #     });
  #   });
  #   settings = {
  #     Theme = {
  #       CursorTheme = "GoogleDot-White";
  #       Font = "Noto Sans,10,-1,0,400,0,0,0,0,0,0,0,0,0,0,1";
  #     };
  #     Users = {
  #       MaximumUid = 60513;
  #       MinimumUid = 1000;
  #     };
  #   };
  # };

  # greetd + tuigreet (lightweight TUI greeter, replaces SDDM)
  # F2 = session list, F3 = session picker, remembers last user+session per user
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = ''
          ${pkgs.tuigreet}/bin/tuigreet \
            --time \
            --asterisks \
            --remember \
            --remember-user-session \
            --sessions ${config.services.displayManager.sessionData.desktops}/share/xsessions:${config.services.displayManager.sessionData.desktops}/share/wayland-sessions
        '';
        user = "greeter";
      };
    };
  };
  services.displayManager.sddm.enable = lib.mkForce false;
  services.desktopManager.plasma6.enable = true;
  programs.hyprland.enable = true;

  # Audio
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Printing
  services.printing.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  hardware.bluetooth.settings.General.Experimental = true;
  services.blueman.enable = true;

  # Power management
  services.power-profiles-daemon.enable = false;
  zramSwap.enable = true;

  services.tlp = {
    enable = true;
    settings.DISK_LAPTOPMODE_ENABLE = 0;
  };
  services.asusd.enable = true;
  systemd.tmpfiles.rules = [
    "d /etc/asusd 0755 root root -"
    "d /var/cache/tuigreet 0755 greeter greeter -"
  ];

  # Fonts
  fonts.packages = with pkgs; [
    material-symbols
    nerd-fonts.jetbrains-mono
  ];

  # Nix settings
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.http2 = false;

  # Shell
  programs.firefox.enable = true;
  programs.zsh.enable = true;
  programs.wireshark.enable = true;

  # FHS compatibility for pip/uv venvs with compiled C extensions (numpy, etc.)
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    openssl
  ];

  # Users
  users.users."richard" = {
    isNormalUser = true;
    description = "richard";
    extraGroups = [ "networkmanager" "wheel" "input" "video" "plocate" "wireshark" ];
    shell = pkgs.zsh;
    packages = with pkgs; [ kdePackages.kate ];
  };

  # System packages
  environment.systemPackages = with pkgs; [
    agenix.packages.x86_64-linux.default
    wireguard-tools
    ffmpeg
    brightnessctl
    touchpad-filter
    reset-touchpad
    sddm-sugar-candy
  ];

  # udev: allow input group to access uinput (needed by touchpad-filter)
  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660"
  '';

  # sudoers: passwordless reset-touchpad
  security.sudo.extraRules = [
    {
      users = [ "richard" ];
      commands = [{
        command = "${reset-touchpad}/bin/reset-touchpad";
        options = [ "NOPASSWD" ];
      }];
    }
  ];

  # Touchpad BTN_LEFT filter (ASUS VivoBook stuck-click firmware bug)
  systemd.user.services.touchpad-filter = {
    description = "Touchpad BTN_LEFT filter";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    unitConfig = {
      StartLimitIntervalSec = "120s";
      StartLimitBurst = 5;
    };
    serviceConfig = {
      Type = "simple";
      ExecStart = "${touchpad-filter}/bin/touchpad-filter";
      Restart = "on-failure";
      RestartSec = "3s";
      StandardOutput = "journal";
      StandardError = "journal";
      SyslogIdentifier = "touchpad-filter";
    };
  };

  # Thermal guard: caps CPU freq when temperature exceeds threshold
  systemd.services.thermal-guard = {
    description = "Thermal-based CPU frequency guard";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "5s";
      ExecStart = pkgs.writeShellScript "thermal-guard" ''
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
        THROTTLE_FREQ=2000000
        THROTTLE_TEMP=85000
        RESTORE_TEMP=75000
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

  services.locate = {
    enable = true;
    locate = pkgs.plocate;
    interval = "daily";
  };

  # Cron
  services.cron = {
    enable = true;
    systemCronJobs = [
      
    ];
  };

  system.stateVersion = "26.05";
}
