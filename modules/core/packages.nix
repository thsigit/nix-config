# modules/core/packages.nix

{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    vim curl wget htop btop psmisc nix-tree tree
    dig mtr nmap tshark tcpdump traceroute iftop bandwhich net-tools inetutils ethtool
    glances zenith nload iotop sysstat bottom
    lshw lsof smartmontools parted gptfdisk efibootmgr lm_sensors libinput evtest pciutils dmidecode file binutils coreutils fetchutils usbutils
    openssl mkcert sops
    rmpc mpc mpv alsa-utils pulsemixer ncmpcpp yewtube musikcube yt-dlp
    go git nodejs_22 jq
    tlp
    fzf tmuxai zensical bc rink exiftool sqlite apache-answer
    claude-code qwen-code codex github-copilot-cli opencode openclaw
  ];
}