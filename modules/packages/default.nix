# modules/packages/default.nix
# All interactive applications (user-invoked) and installed packages.

{ config, lib, pkgs, ... }:

{
  imports = [
    ./ydotool.nix
    ./bash.nix
    ./tmux.nix
    ./vim.nix
    ./git.nix
    ./fzf.nix
    ./htop.nix
    ./bandwhich.nix
    ./iftop.nix
    ./iotop.nix
    ./tcpdump.nix
    ./traceroute.nix
    ./wireshark.nix
  ];

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
    openssl mkcert sops
    sqlite alejandra
    tlp
    tmuxai apache-answer
    dig mtr nmap tshark net-tools inetutils ethtool iw nftables
    lshw lsof smartmontools lm_sensors libinput evtest pciutils fetchutils usbutils
    parted gptfdisk efibootmgr dmidecode psmisc
    mpv yt-dlp
    ncmpcpp rmpc mpc musikcube
    alsa-utils pulsemixer
    yewtube
  ];
}
