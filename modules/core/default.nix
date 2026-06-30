# modules/core/default.nix

{ config, lib, pkgs, ... }:

{
  imports = [
    ./boot.nix
    ./kernel.nix
    ./locale.nix
    ./networking.nix
    ./packages.nix
    ./services.nix
    ./users.nix
  ];  

  # Nix Daemon Settings & Garbage Collection
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

  # State Version
  system.stateVersion = "25.11";
}