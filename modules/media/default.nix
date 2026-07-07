# modules/media/default.nix 

{ config, lib, pkgs, ... }:

{  
  imports = [
    ./bluetooth.nix
    ./mpd.nix
    ./navidrome.nix
    ./trilium-server.nix
    #./lidarr.nix
    #./pulseaudio.nix
	#./pipewire.nix
    ./podman-calibre-web.nix
    ./podman-wallabag.nix
    ./podman-linkding.nix
    # ./podman-qbittorrent.nix
    # ./podman-transmission.nix
  ];
}