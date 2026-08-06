# profiles/workstation/default.nix
{ config, lib, pkgs, callPackage, ... }:
{
  imports = [
    ../../system
    #../../modules/ap
    ../../programs
    ../../modules
    ./xfce4.nix
    ./packages.nix
  ];

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "google-chrome"
  ];
}
