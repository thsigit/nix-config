# modules/media/trilium-server.nix

{ config, pkgs, ... }:

let
  defaults = import ../../settings;
  inherit (defaults.directories) appdata;

  appdataDir = "${appdata}/trillium";
in

{
  services.caddy.services.triliumnotes = {
    port = 8088;
  };

  services.trilium-server = {
    enable = true;
    dataDir = "${appdataDir}/data";
    host = "127.0.0.1";
    port = 8088;
    instanceName = "Trilium";
    noAuthentication = false;
    noBackup = false;
    package = pkgs.trilium-server;
  };

  systemd.tmpfiles.rules = [
    "d ${appdataDir} 0755 trilium trilium -"
    "d ${appdataDir}/data 0755 trilium trilium -"
  ];
}
