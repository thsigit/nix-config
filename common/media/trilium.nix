# common/media/trilium.nix
# Trilium notes — enable + config. Upstream `services.trilium-server` owns the
# user/group and dataDir; local concern is only the persistent parent dir (the
# "srv" partition survives reformats) and the Caddy vhost.
#
# NOTE on the data path: kept as ${appdata}/trilium (the correct product
# spelling). The historical misspelling /srv/appdata/trillium was migrated to
# /srv/appdata/trilium on the host (data preserved, ownership trilium:trilium).

{ config, pkgs, ... }:
let
  defaults = import ../../settings;
  inherit (defaults.directories) appdata;
  appdataDir = "${appdata}/trilium";
in
{
  services.caddy.services.triliumnotes = { port = 8088; };
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
  # tmpfiles create the parent dirs on fresh installs. The migrated data dir
  # already exists owned trilium:trilium (host-side mv preserved ownership).
  systemd.tmpfiles.rules = [
    "d ${appdataDir} 0755 trilium trilium -"
    "d ${appdataDir}/data 0755 trilium trilium -"
  ];
}
