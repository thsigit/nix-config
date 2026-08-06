# modules/packages/fzf.nix

{ config, lib, pkgs, ... }:

{
  programs.fzf = {
    keybindings = true;
    fuzzyCompletion = true;
  };
}
