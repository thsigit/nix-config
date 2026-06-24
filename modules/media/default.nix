# modules/media/default.nix 

{ config, lib, pkgs, ... }:

{  
  imports = [
    #./pulseaudio.nix
	#./pipewire.nix
    ./bluetooth.nix
    ./calibre-web.nix
    ./wallabag.nix
    ./linkding.nix
    ./mpd.nix
    ./navidrome.nix
    # ./lidarr.nix
    # ./qbittorrent.nix
    # ./transmission.nix
  ];
}