# programs/nix.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    nix-tree
  ];
}
