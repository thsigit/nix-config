# modules/media/default.nix 

{ config, lib, pkgs, ... }:

{  
  imports = [
    #./pulseaudio.nix
	#./pipewire.nix
    ./bluetooth.nix
    ./podman-calibre-web.nix
    ./podman-wallabag.nix
    ./podman-linkding.nix
    ./mpd.nix
    ./navidrome.nix
    ./trilium-server.nix
    # ./lidarr.nix
    # ./podman-qbittorrent.nix
    # ./podman-transmission.nix
  ];
}