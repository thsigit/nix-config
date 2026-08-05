# modules/media/default.nix 

{  
  imports = [
    ./bluetooth.nix
    ./mpd.nix
    ./navidrome.nix
    ./trilium-server.nix
    ./calibre-web.nix
    ./karakeep.nix
    ./podman-linkding.nix
  ];
  security.rtkit.enable = true; 
}
