# programs/nodejs.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    nodejs_22
  ];
}
