# programs/tree.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    tree file binutils moreutils
  ];
}
