# modules/packages/vim.nix

{ config, lib, pkgs, ... }:

{
  programs.vim = {
    enable = true;
    defaultEditor = true;
  };
}
