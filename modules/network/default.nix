# modules/network/default.nix 

{ config, lib, pkgs, ... }:

{
  imports = [
    ./tailscale.nix
    ./zerotier.nix
    # ./adguard.nix
    # ./dnsmasq.nix
  ];
  networking.networkmanager.dns = "systemd-resolved";
  services.resolved.enable = true;
}
