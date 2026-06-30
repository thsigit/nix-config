# modules/media/wallabag.nix

{ config, pkgs, lib, ... }:

let
  defaults = import ../../lib;
in


{
  virtualisation.oci-containers.containers.wallabag = {
    image = "wallabag/wallabag:latest";
    ports = [ "8085:80" ];
    volumes = [
      "${defaults.appdataDir}/wallabag/data:/var/www/wallabag/data"
      "${defaults.appdataDir}/wallabag/images:/var/www/wallabag/web/assets/images"
    ];
    environment = {
      SYMFONY__ENV__DATABASE_DRIVER = "pdo_sqlite";
      SYMFONY__ENV__DATABASE_PATH = "/var/www/wallabag/data/db.sqlite";
      SYMFONY__ENV__DOMAIN_NAME = "https://wallabag.home.arpa/";
    };
  };
  systemd.tmpfiles.rules = [
    "d ${defaults.appdataDir}/wallabag/data 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.appdataDir}/wallabag/images 0755 ${defaults.user} ${defaults.group} -"
  ];
}
