# commons/network/dnsmasq.nix
{ config, pkgs, ... }:
{
  services.dnsmasq = {
    enable = true;
    settings = {
      interface = [ "enp0s31f6" ];
      bind-interfaces = true;
      listen-address = [ "127.0.0.1" "192.168.1.3" ];
      address = [
        "/home.arpa/192.168.1.3"
      ];
    };
  };
  systemd.services.dnsmasq = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };
  environment.systemPackages = [ pkgs.dnsmasq ];
}
