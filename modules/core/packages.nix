# modules/core/packages.nix

{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    vim curl wget coreutils psmisc nix-tree tree # diagnostic
    dig mtr nmap tshark tcpdump traceroute iftop bandwhich net-tools inetutils ethtool # network-diagnostic
    htop btop glances zenith nload iotop sysstat bottom # system-monitoring
    lshw lsof smartmontools lm_sensors libinput evtest pciutils fetchutils usbutils # hardware-diagnostic
    parted gptfdisk efibootmgr dmidecode # low-level hardware-tools
	openssl mkcert sops #security
    rmpc mpc mpv alsa-utils pulsemixer ncmpcpp yewtube musikcube yt-dlp #media
    go git nodejs_22 jq yq alejandra # programming
    file binutils # low-level software-tools
    apache-answer fzf tmuxai bc rink exiftool sqlite tlp # misc
  ];
}