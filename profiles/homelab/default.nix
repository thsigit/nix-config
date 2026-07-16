# profiles/homelab/default.nix

{ config, lib, pkgs, ... }:

{
  imports = [
    ../../modules/core
    ../../modules/network      # tailscale, zerotier, dnsmasq
    ../../modules/storage      # mount SSD, rsync, samba, vsftpd
    ../../modules/security     # pki.nix, sertifikat CA
    ../../modules/monitoring   # cockpit, darkstat, mrtg
    ../../modules/caddy        # caddy reverse proxy
    ../../modules/media        # pipewire and alsa
    ../../modules/ai           # ollama etc
  ];

}
