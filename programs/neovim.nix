# programs/neovim.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    vim
  ];
}
