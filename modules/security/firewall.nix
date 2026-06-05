# modules/apps/security/default.nix 

{ config, lib, pkgs, ... }:

{
  # Firewall global
  networking.firewall = {
    enable = true;
    allowPing = true;
    allowedTCPPorts = [ 22 80 443 9090 ];
    allowedUDPPorts = [ 9 161 9993 41641 ];
    allowedTCPPortRanges = [
      { from = 51000; to = 51999; }
    ];
  };
}