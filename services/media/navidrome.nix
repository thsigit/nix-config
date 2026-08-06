# services/media/navidrome.nix
{ config, ... }:
let
  defaults = import ../../settings;
  inherit (defaults) user;
  inherit (defaults.directories) appdata media;
  appdataDir = "${appdata}/navidrome";
in
{
  services.caddy.services.navidrome = { port = 4533; };
  services.navidrome = {
    enable = true;
    user = user.name;
    group = user.group;
    settings = {
      DataFolder = "${appdataDir}/data";
      MusicFolder = "${media}/music";
      ScanSchedule = "1h";
      LogLevel = "info";
      SessionTimeout = "24h";
      BaseUrl = "/navidrome";
      Address = "127.0.0.1";
      Port = 4533;
    };
  };
  systemd.tmpfiles.rules = [
    "d ${media} 0755 ${user.name} ${user.group} -"
    "d ${media}/music 0755 ${user.name} ${user.group} -"
    "d ${appdataDir}/data 0755 ${user.name} ${user.group} -"
  ];
}
