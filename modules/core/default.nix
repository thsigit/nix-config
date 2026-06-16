# modules/core/default.nix

{ config, lib, pkgs, ... }:

{
  # boot.uki.name = "nixos";
  boot.loader = {
    systemd-boot = {
      enable = false;
      configurationLimit = 10;
    };
	
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      gfxmodeEfi = "text";
      configurationLimit = 5;
      useOSProber = false;
      splashImage = null;
      extraGrubInstallArgs = [
        "--bootloader-id=GRUB"
      ];
    };

    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };

    timeout = 0;
  };

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # Kernel Parameters & Powermanagement

  # Kernel parameters
  boot.kernelParams = [
    "quiet" "loglevel=3" "consoleblank=60" "acpi_osi=Linux"
    "initcall_blacklist=atkbd_init" # DAN MATIKAN KEYBOARD
    "ahci.mobile_lpm_policy=0" # DAN MATIKAN LPM
    "libata.force=1.00:disable" # dan bypass ATA 1
  ];

  services.logind.settings.Login.HandleLidSwitch = "ignore";
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };
  
  # Networking (Core)
  networking = {
    hostName = "homelab";
    domain = "home.arpa";
    extraHosts = ''
      192.168.1.3 homelab.home.arpa homelab
    '';
  };  
  
  networking.networkmanager.enable = true;

  # Regional & Locale
  time.timeZone = "Asia/Makassar";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "id_ID.UTF-8";
    LC_IDENTIFICATION = "id_ID.UTF-8";
    LC_MEASUREMENT = "id_ID.UTF-8";
    LC_MONETARY = "id_ID.UTF-8";
    LC_NAME = "id_ID.UTF-8";
    LC_NUMERIC = "id_ID.UTF-8";
    LC_PAPER = "id_ID.UTF-8";
    LC_TELEPHONE = "id_ID.UTF-8";
    LC_TIME = "id_ID.UTF-8";
  };
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # User Account
  users.users.sigit = {
    isNormalUser = true;
    description = "Sigit Prasetyo";
    extraGroups = [ "networkmanager" "wheel" "audio" "video" "podman" "ydotool" ];
    packages = with pkgs; [];
  };

  services.getty.autologinUser = "sigit";

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "openclaw-2026.5.7"
  ];

  # System Packages
  environment.systemPackages = with pkgs; [

    #Core
    vim curl wget htop btop lshw lsof smartmontools parted gptfdisk efibootmgr lm_sensors psmisc libinput evtest

    # Network
    dig mtr nmap tshark tcpdump traceroute iftop bandwhich net-tools inetutils ethtool

    # Monitoring
    glances zenith nload iotop sysstat

    # Security
    openssl mkcert

    # Media
    rmpc mpc mpv alsa-utils pulsemixer ncmpcpp yewtube musikcube 

    # Programming
    go git

    # Misc
    sqlite exiftool fzf file dmidecode tree binutils tmuxai zensical apache-answer coreutils fetchutils usbutils bottom tlp bc rink yt-dlp nix-tree

    # LLM
    ollama-cpu claude-code qwen-code codex github-copilot-cli opencode openclaw
  ];
  
  # CLI tool
  programs.ydotool.enable = true;

  programs.tmux = {
    enable = true;
    aggressiveResize = true;
    # terminal = "screen-256color";
    historyLimit = 10000;
    clock24 = true;
    extraConfig = ''
      set -g @continuum-restore 'on'
      set -g @continuum-save-interval '60'
    
      # set -g @resurrect-capture-pane-contents 'on'
      set -g @resurrect-processes 'ssh'

      set -g @thumbs-key 't'
      set -g @thumbs-unique 'enabled'
      set -g @tmux_power_theme 'gold'
      set -g default-terminal "screen-256color"
      set -as terminal-features ",xterm-256color:RGB"
    '';
    newSession = true;
    plugins = with pkgs.tmuxPlugins; [
      resurrect
      continuum
      tmux-fzf
      extrakto

      session-wizard
      yank
      tmux-thumbs
  
      cpu
      power-theme

      sensible
    ];
  };

  # Nix Daemon Settings & Garbage Collection
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # State Version
  system.stateVersion = "25.11";
}