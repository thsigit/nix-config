# programs/htop.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    htop btop glances zenith bottom
  ];
}
