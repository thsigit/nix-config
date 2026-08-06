# services/network/default.nix
{ config, ... }:
{
  imports = [
    ./tailscale.nix
    ./zerotier.nix
    ./dnsmasq.nix
  ];
  networking.networkmanager.dns = "systemd-resolved";
  services.resolved.enable = true;
}
