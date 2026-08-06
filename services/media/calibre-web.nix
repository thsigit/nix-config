# services/media/calibre-web.nix
{ config, ... }:
let
  defaults = import ../../settings;
  inherit (defaults) user;
  inherit (defaults.directories) appdata media;
  appdataDir = "${appdata}/calibre";
in
{
  services.calibre-web = {
    enable = true;
    listen.ip = "0.0.0.0";
    listen.port = 8083;
    user = user.name;
    group = user.group;
    dataDir = "${appdataDir}/config-web";
    options = {
      calibreLibrary = "${media}/books";
      enableBookConversion = true;
      enableBookUploading = true;
    };
  };
  services.caddy.services.calibre = { port = 8083; };
  systemd.tmpfiles.rules = [
    "d ${media}/books 0755 ${user.name} ${user.group} -"
    "d ${media}/uploads 0775 ${user.name} ${user.group} -"
    "d ${appdataDir} 0755 ${user.name} ${user.group} -"
    "d ${appdataDir}/config-web 0755 ${user.name} ${user.group} -"
  ];
}
