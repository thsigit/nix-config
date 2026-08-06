# programs/copyparty.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    copyparty exiftool
  ];
}
