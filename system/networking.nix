# system/networking.nix
# Machine networking: hostname, domain, LAN static IP on the wired NIC.
# Machine-specific values come from settings/network (single source of truth).

{ config, lib, pkgs, ... }:
let
  defaults = import ../settings;
  inherit (defaults) domain;
  inherit (defaults.network) lanInterface lanIp lanPrefix gateway;
in
{
  networking = {
    hostName = "homelab";
    inherit domain;
    extraHosts = ''
      ${lanIp} homelab.${domain} homelab
    '';
  };

  networking.networkmanager.enable = true;

  # WAN is the wired ethernet NIC. Pin it to the static address (${lanIp});
  # DHCP is only used until this config is applied.
  networking.networkmanager.unmanaged = [ "interface-name:${lanInterface}" ];
  networking.interfaces.${lanInterface}.ipv4.addresses = [{
    address = lanIp;
    prefixLength = lanPrefix;
  }];
  networking.defaultGateway = gateway;
  networking.nameservers = [ gateway "1.1.1.1" ];
}
