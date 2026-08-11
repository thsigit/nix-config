# commons/media/default.nix
{ ... }:
{
  imports = [
    ./navidrome.nix
    ./karakeep.nix
    ./trilium.nix
    ./calibre-web.nix
    ./mpd.nix
    ./linkding-container.nix
  ];
}
