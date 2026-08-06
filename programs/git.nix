# programs/git.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git tig gh
  ];
}
