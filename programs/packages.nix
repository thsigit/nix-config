# programs/packages.nix
# All interactive applications and user-invoked tools (except shell config).

{ config, lib, pkgs, ... }:

{
  imports = [
    ./shell.nix
  ];

  environment.systemPackages = with pkgs; [
    bc rink
    copyparty exiftool
    curl wget
    fzf
    git tig gh
    go
    jq yq
    htop btop glances zenith bottom
    tree file binutils moreutils
    nix-tree
    nodejs_22
    openssl mkcert sops
    sqlite alejandra
    tlp
    tmuxai apache-answer
    dig mtr nmap tshark tcpdump traceroute iftop bandwhich net-tools inetutils ethtool iw nftables
    lshw lsof smartmontools lm_sensors libinput evtest pciutils fetchutils usbutils
    parted gptfdisk efibootmgr dmidecode psmisc
    mpv yt-dlp
    ncmpcpp rmpc mpc musikcube
    alsa-utils pulsemixer
    vim
    yewtube
  ];
}
