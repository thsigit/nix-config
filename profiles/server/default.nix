# profiles/server.nix 

{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../module/core
    ../../module/network      # tailscale, zerotier, dnsmasq
    ../../module/storage      # mount SSD, rsync, samba, vsftpd
    ../../module/security     # pki.nix, sertifikat CA
    ../../module/monitoring   # cockpit, darkstat, mrtg
    ../../module/web          # caddy server
    ../../module/media        # pipewire and alsa
    ../../module/ai           # ollama etc
  ];
}
