# modules/apps/default.nix 

{ config, lib, pkgs, ... }:

{
  # Podman Engine
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
  
  imports = [
    # ./lidarr.nix
    ./linkding.nix  
    ./wallabag.nix
    ./navidrome.nix
    ./calibre-web.nix
    ./mpd.nix
  ];
}