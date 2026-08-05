# profiles/workstation/default.nix

{ config, pkgs, callPackage, ... }:

{
  imports = [
    ../../modules/core
    ../../modules/network # tailscale, zerotier, dnsmasq
    ../../modules/storage # mount SSD, rsync, samba, vsftpd
    ../../modules/security # pki.nix, sertifikat CA
    ../../modules/monitoring # cockpit, darkstat, mrtg
    ../../modules/caddy # caddy reverse proxy
    ../../modules/media # pipewire and alsa
    #../../modules/ai # ollama etc
    ./xfce4.nix
    ./packages.nix
  ];
}
