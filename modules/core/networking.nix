# modules/core/networking.nix

{ config, lib, pkgs, ... }:
{
  networking = {
    hostName = "homelab";
    domain = "home.arpa";
    extraHosts = ''
      192.168.1.3 homelab.home.arpa homelab
    '';
  };

  networking.networkmanager.enable = true;
}