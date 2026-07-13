# modules/media/navidrome.nix

{ config, ... }:

let
  defaults = import ../../settings;
  inherit (defaults) 
    user 
    directories;
  appdataDir = "${directories.appdata}/navidrome";
  mediaRoot = directories.media;
in

{
  services.navidrome = {
    enable = true;
    user = user.name;
    group = user.group;

    settings = {
      DataFolder = "${appdataDir}/data";
      MusicFolder = "${mediaRoot}/music";
      ScanSchedule = "1h";
      LogLevel = "info";
      SessionTimeout = "24h";
      BaseUrl = "/navidrome";
      Address = "127.0.0.1";
      Port = 4533;
    };
  };

  systemd.tmpfiles.rules = [
    "d ${mediaRoot} 0755 ${user.name} ${user.group} -"
    "d ${mediaRoot}/music 0755 ${user.name} ${user.group} -"
    "d ${appdataDir}/data 0755 ${user.name} ${user.group} -"
  ];
}