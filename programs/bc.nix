# programs/bc.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    bc rink
  ];
}
