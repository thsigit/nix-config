# modules/security/insecure-packages.nix
{ config, pkgs, ... }:

{
  nixpkgs.config.permittedInsecurePackages = [
    "openclaw-2026.5.7"
  ];
}