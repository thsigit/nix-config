# programs/dig.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    dig mtr nmap tshark tcpdump traceroute iftop bandwhich net-tools inetutils ethtool iw nftables
  ];
}
