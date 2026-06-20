# modules/media/navidrome.nix

{ config, pkgs, lib, ... }:

let
  defaults = import ../../lib;
in

{
  services.navidrome = {
    enable = true;
    user = defaults.user;
    group = defaults.group;
    
    settings = {
      DataFolder = "${defaults.appDir}/navidrome/data";
      MusicFolder = "${defaults.dataDir}/music";
      ScanSchedule = "1h";
      LogLevel = "info";
      SessionTimeout = "24h";
      BaseUrl = "/navidrome";
      Address = "127.0.0.1";
      Port = 4533;
    };
  };

  systemd.tmpfiles.rules = [
    "d ${defaults.dataDir}/music 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.appDir}/navidrome/data 0755 ${defaults.user} ${defaults.group} -"
  ];
}