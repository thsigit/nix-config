# modules/monitoring/default.nix 

{ config, ... }:

{
  imports = [
    #./mrtg.nix
    ./darkstat.nix
    ./cockpit.nix
  ];

  services.darkstat.enable = true;
}
