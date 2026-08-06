# programs/tlp.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    tlp
  ];
}
