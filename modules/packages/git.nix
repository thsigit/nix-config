# programs/git.nix

{ config, lib, pkgs, ... }:

{
  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
    };
  };
}
