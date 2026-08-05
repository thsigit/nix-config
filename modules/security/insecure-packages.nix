# modules/security/insecure-packages.nix
{ config, pkgs, ... }:

{
  nixpkgs.config.permittedInsecurePackages = [ ];
}