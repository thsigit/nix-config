# system/default.nix
# Operating system configuration — boot, kernel, locale, networking, users, security.
{ config, lib, pkgs, ... }:
{
  imports = [
    ./boot.nix
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

  system.stateVersion = "25.11";
}
