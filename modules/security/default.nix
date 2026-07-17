# modules/security/default.nix 

{ config, lib, pkgs, ... }:

{  
  imports = [
    ./insecure-packages.nix
    ./pki.nix
    ./ssh.nix
    ./firewall.nix
    ./sops.nix
    ./sudo.nix
  ];
}