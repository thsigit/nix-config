# modules/monitoring/default.nix
{ ... }:
{
  imports = [
    ./cockpit.nix
    ./darkstat.nix
    ./mrtg.nix
  ];
  services.darkstat = {
    enable = true;
    interface = "enp0s31f6";
  };
}
