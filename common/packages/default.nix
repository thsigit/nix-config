# common/packages/default.nix
# Installed packages and enableable programs. Shell config and power tuning
# live in system/ (shell.nix, power.nix) — this module is software only.

{ config, lib, pkgs, ... }:
{
  programs.fzf = {
    keybindings = true;
    fuzzyCompletion = true;
  };

  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
    };
  };

  programs.tmux = {
    enable = true;
    aggressiveResize = true;
    historyLimit = 10000;
    clock24 = true;
    extraConfig = ''
      set -g @continuum-restore on
      set -g @continuum-save-interval 60
      set -g @resurrect-capture-pane-contents on
      set -g @resurrect-processes ssh
      set -g @thumbs-key t
      set -g @thumbs-unique enabled
      set -g @tmux_power_theme gold
      set -g default-terminal screen-256color
      set -as terminal-features ,xterm-256color:RGB
    '';
    newSession = true;
    plugins = with pkgs.tmuxPlugins; [
      resurrect continuum tmux-fzf extrakto session-wizard yank
      tmux-thumbs cpu power-theme sensible
    ];
  };

  programs.vim = {
    enable = true;
    defaultEditor = true;
  };

  programs.wireshark = {
    enable = true;
    package = lib.mkDefault pkgs.tshark;
  };

  programs.bandwhich.enable = true;
  programs.htop.enable = true;
  programs.iftop.enable = true;
  programs.iotop.enable = true;
  programs.tcpdump.enable = true;
  programs.traceroute.enable = true;
  programs.ydotool.enable = true;

  environment.systemPackages = with pkgs; [
    bc rink
    copyparty exiftool
    curl wget
    tig gh
    go
    jq yq
    btop glances zenith bottom
    tree file binutils moreutils
    nix-tree
    nodejs_22
    python3 uv
    openssl mkcert sops
    sqlite alejandra
    tlp
    tmuxai apache-answer
    dig mtr nmap net-tools inetutils ethtool iw nftables
    lshw lsof smartmontools lm_sensors libinput evtest pciutils fetchutils usbutils
    parted gptfdisk efibootmgr dmidecode psmisc
    mpv yt-dlp
    ncmpcpp rmpc mpc musikcube
    alsa-utils pulsemixer
    yewtube
  ];
}
