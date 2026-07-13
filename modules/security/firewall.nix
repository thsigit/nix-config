# modules/security/firewall.nix 

{ config, ... }:

{
  # Global firewall
  networking.firewall = {
    enable = true;
    allowPing = true;
    allowedTCPPorts = [ 22 80 443 3923 8000 9090 ];
    allowedUDPPorts = [ 9 161 9993 41641 ];
    allowedTCPPortRanges = [
      { from = 51000; to = 51999; }
    ];
  };
}