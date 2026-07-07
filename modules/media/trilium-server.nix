# modules/media/trilium-server.nix
{ config, pkgs, lib, ... }:

let
  defaults = import ../../lib;
in

{
  services.trilium-server = {
    enable = true;
    dataDir = "${defaults.appdataDir}/trillium/data";
    host = "127.0.0.1";
    port = 8088;
    instanceName = "Trilium";
    noAuthentication = false;
    noBackup = false;
    package = pkgs.trilium-server;
  };

  # trilium-server menggunakan user/grups-nya sendiri
  systemd.tmpfiles.rules = [
    "d ${defaults.appdataDir}/trillium 0755 trilium trilium -"
    "d ${defaults.appdataDir}/trillium/data 0755 trilium trilium -"
	];
}