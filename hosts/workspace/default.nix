# hosts/workspace/default.nix

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core
    ../../modules/network      # tailscale, zerotier, dnsmasq
    ../../modules/storage      # mount SSD, rsync, samba, vsftpd
    ../../modules/security     # pki.nix, sertifikat CA
    ../../modules/monitoring   # cockpit, darkstat, mrtg
    ../../modules/web          # caddy server
    ../../modules/media        # pipewire and alsa
    ../../modules/ai           # ollama etc
  ];

  # Enable Plasma
  services = {
    desktopManager.plasma6.enable = true;
    displayManager.plasma-login-manager.enable = true;
  };
}
