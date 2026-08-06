# modules/monitoring/default.nix
{ ... }:
{
  imports = [
    ./cockpit.nix
    ./darkstat.nix
    #./mrtg.nix
  ];
}
