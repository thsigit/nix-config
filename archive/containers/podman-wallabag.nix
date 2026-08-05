# modules/media/podman-wallabag.nix

{ config, ... }:

let
  defaults = import ../../settings;
  inherit (defaults) user;
  inherit (defaults.directories) appdata;

  appdataDir = "${appdata}/wallabag";
in

{
  services.caddy.services.wallabag = {
    port = 8085;
  };

  virtualisation.oci-containers.containers.wallabag = {
    image = "wallabag/wallabag:latest";
    ports = [ "8085:80" ];
    volumes = [
      "${appdataDir}/data:/var/www/wallabag/data"
      "${appdataDir}/images:/var/www/wallabag/web/assets/images"
    ];
    environment = {
      SYMFONY__ENV__DATABASE_DRIVER = "pdo_sqlite";
      SYMFONY__ENV__DATABASE_PATH = "/var/www/wallabag/data/db.sqlite";
      SYMFONY__ENV__DOMAIN_NAME = "https://wallabag.home.arpa/";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${appdataDir}/data 0755 ${user.name} ${user.group} -"
    "d ${appdataDir}/images 0755 ${user.name} ${user.group} -"
  ];
}
