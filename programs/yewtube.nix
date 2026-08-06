# programs/yewtube.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    yewtube
  ];
}
