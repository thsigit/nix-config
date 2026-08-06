# programs/fzf.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    fzf
  ];
}
