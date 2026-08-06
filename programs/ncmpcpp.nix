# programs/ncmpcpp.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    ncmpcpp rmpc mpc musikcube
    alsa-utils pulsemixer
  ];
}
