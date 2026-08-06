# programs/fzf.nix

{ config, lib, pkgs, ... }:

{
  programs.fzf = {
    enable = true;
    keybindings = true;
    fuzzyCompletion = true;
  };
}
