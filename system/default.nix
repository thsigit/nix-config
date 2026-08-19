# system/default.nix
# Operating system configuration — boot, kernel, locale, networking, users, security.
{ config, lib, pkgs, ... }:
{
  imports = [
    ./boot.nix
    ./grub-failsafe.nix
    ./kernel.nix
    ./locale.nix
    ./networking.nix
    ./users.nix
    ./bluetooth.nix
    ./firewall.nix
    ./sudo.nix
    ./pki.nix
    ./ssh.nix
    ./sops.nix
  ];

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # karakeep builds against pnpm-9.15.9, which newer nixpkgs flags as insecure.
  nixpkgs.config = {
    permittedInsecurePackages = [ "pnpm-9.15.9" ];
  };

  system.stateVersion = "25.11";
}
