# modules/media/calibre-web.nix
# TO DO: migrasi ke https://search.nixos.org/options?channel=25.11&query=services.calibre-web

{ config, pkgs, lib, ... }:

let
  defaults = import ../../lib;
in

{
  virtualisation.oci-containers.containers.calibre-web = {
    image = "lscr.io/linuxserver/calibre-web:latest";
    ports = [ "8083:8083" ];
    volumes = [
      "${defaults.mediaDir}/books:/books"
      "${defaults.appdataDir}/calibre/config-web:/config"
      "${defaults.mediaDir}/uploads:/uploads"
    ];
    environment = defaults.baseEnv;
    autoStart = true;
  };
  systemd.tmpfiles.rules = [
    "d ${defaults.mediaDir}/books 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.mediaDir}/uploads 0775 ${defaults.user} ${defaults.group} -"
    "d ${defaults.appdataDir}/calibre/config-web 0755 ${defaults.user} ${defaults.group} -"
  ];
}
