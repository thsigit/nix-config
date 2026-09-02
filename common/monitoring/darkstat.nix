# common/monitoring/darkstat.nix
#
# Self-contained, always-on leaf (mrtg-style): no custom options — just a
# systemd unit under the built-in systemd.services namespace. Importing this
# file enables darkstat on the default interface. This is the standard shape
# for leaf service modules in this repo (see mrtg.nix).
{ config, pkgs, ... }:
let
  interface = "enp0s31f6";
in
{
  services.caddy.services.darkstat = { port = 667; visibility.tailscale = false; };
  environment.systemPackages = [ pkgs.darkstat ];
  systemd.services.darkstat = {
    description = "Darkstat Traffic Monitor";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.darkstat}/bin/darkstat -i ${interface} --no-daemon";
      Restart = "on-failure";
    };
  };
}
