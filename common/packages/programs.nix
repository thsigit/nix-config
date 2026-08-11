# common/packages/programs.nix
# Diagnostic and system tools.

{ config, lib, pkgs, ... }:

{
  programs.bandwhich.enable = true;
  programs.htop.enable = true;
  programs.iftop.enable = true;
  programs.iotop.enable = true;
  programs.tcpdump.enable = true;
  programs.traceroute.enable = true;
  programs.ydotool.enable = true;
}
