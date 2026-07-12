# modules/monitoring/default.nix 

{ config, lib, pkgs, ... }:

{
  imports = [
    ./mrtg.nix
    ./darkstat.nix
    ./cockpit.nix
  ];

  services.darkstat = {
    enable = true;
    interface = "enp0s31f6";
  };
}