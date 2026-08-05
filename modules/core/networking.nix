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

  # WAN is the wired ethernet NIC. Pin it to the static address (192.168.1.3);
  # DHCP is only used until this config is applied.
  networking.networkmanager.unmanaged = [ "interface-name:enp0s31f6" ];
  networking.interfaces.enp0s31f6.ipv4.addresses = [{
    address = "192.168.1.3";
    prefixLength = 24;
  }];
  networking.defaultGateway = "192.168.1.1";
  networking.nameservers = [ "192.168.1.1" "1.1.1.1" ];
}
