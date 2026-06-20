# /etc/nixos/configuration.nix 

{ config, lib, pkgs, ... }:

{
  imports = [
    # Hardware Scan
    ./hardware-configuration.nix

    # Core System Settings (Hasil Ekstraksi)
    ./modules/core
    #./modules/specialisation

    # TAMBAHKAN MODUL-MODUL BARU ANDA DI SINI:
    ./modules/network      # tailscale, zerotier, dnsmasq
    ./modules/storage      # mount SSD, rsync, samba, vsftpd
    ./modules/security     # pki.nix, sertifikat CA
    ./modules/monitoring   # cockpit, darkstat, mrtg
    ./modules/web          # caddy server
    ./modules/apps         # podman and containers
    ./modules/media        # pipewire and alsa
    ./modules/ai           # ollama etc
  ];
}
