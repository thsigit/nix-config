# profiles/homelab/default.nix

{ config, lib, pkgs, ... }:

{
  imports = [
    ../../modules/core
    ../../modules/network      # tailscale, zerotier, dnsmasq
    ../../modules/storage      # mount SSD, rsync, samba, vsftpd
    ../../modules/security     # pki.nix, sertifikat CA
    ../../modules/monitoring   # cockpit, darkstat, mrtg
    ../../modules/web          # caddy server
    ../../modules/media        # pipewire and alsa
    ../../modules/ai           # ollama etc
  ];

#  boot.kernelParams = lib.mkAfter [
#    "initcall_blacklist=atkbd_init" # physical laptop keyboard disabled
#  ];

}
