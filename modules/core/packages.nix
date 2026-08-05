# modules/core/packages.nix

{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    vim curl wget coreutils psmisc nix-tree tree # diagnostic
    htop btop glances zenith nload iotop sysstat bottom # system-monitoring
    lshw lsof smartmontools lm_sensors libinput evtest pciutils fetchutils usbutils # hardware-diagnostic
    nftables iw dig mtr nmap tshark tcpdump traceroute iftop bandwhich net-tools inetutils ethtool # network-tools
    parted gptfdisk efibootmgr dmidecode # hardware-tools
    file binutils moreutils # software-tools
    openssl mkcert sops #security
    copyparty exiftool rmpc mpc mpv alsa-utils pulsemixer ncmpcpp yewtube musikcube yt-dlp #media
    go git tig gh nodejs_22 jq yq sqlite alejandra # programming
    apache-answer fzf tmuxai bc rink tlp # misc
  ];
}
