# modules/media/default.nix 

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
    ./karakeep.nix
    ./podman-wallabag.nix
    ./podman-linkding.nix
    # ./podman-qbittorrent.nix
    # ./podman-transmission.nix
  ];
}