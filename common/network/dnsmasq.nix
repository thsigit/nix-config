# common/network/dnsmasq.nix
# LAN DNS/DHCP via dnsmasq, bound to the machine's LAN interface/address.
# Values come from settings/network (single source of truth).

{ config, pkgs, ... }:
let
  defaults = import ../../settings;
  inherit (defaults) domain;
  inherit (defaults.network) lanInterface lanIp;
in
{
  services.dnsmasq = {
    enable = true;
    settings = {
      interface = [ lanInterface ];
      bind-interfaces = true;
      listen-address = [ "127.0.0.1" lanIp ];
      address = [
        "/${domain}/${lanIp}"
      ];
    };
  };
  systemd.services.dnsmasq = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };
  environment.systemPackages = [ pkgs.dnsmasq ];
}
