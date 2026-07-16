# modules/media/podman-calibre-web.nix
# TO DO: migrasi ke https://search.nixos.org/options?channel=25.11&query=services.calibre-web

{ config, ... }:

let
  defaults = import ../../settings;
  inherit (defaults) 
    user 
    directories 
    baseEnv;
  appdataDir = "${directories.appdata}/calibre";
  mediaRoot = directories.media;
in

{
  services.caddy.services.calibre = {
    port = 8083;
  };

  virtualisation.oci-containers.containers.calibre-web = {
    image = "lscr.io/linuxserver/calibre-web:latest";
    ports = [ "8083:8083" ];
    volumes = [
      "${mediaRoot}/books:/books"
      "${mediaRoot}/uploads:/uploads"
      "${appdataDir}/config-web:/config"
    ];
    environment = baseEnv;
    autoStart = true;
  };
  systemd.tmpfiles.rules = [
    "d ${mediaRoot}/books 0755 ${user.name} ${user.group} -"
    "d ${mediaRoot}/uploads 0775 ${user.name} ${user.group} -"
    "d ${appdataDir} 0755 ${user.name} ${user.group} -"
    "d ${appdataDir}/config-web 0755 ${user.name} ${user.group} -"
  ];
}
