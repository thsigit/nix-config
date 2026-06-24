# modules/media/lidarr.nix

{ config, pkgs, lib, ... }:

let
  defaults = import ../../lib;
in

{
  services.lidarr = {
    enable = true;
    user = defaults.user;
    group = defaults.group;
    mediaDir = "${defaults.appdataDir}/lidarr/config";
    settings = {
      server = {
      port = 8686;
      urlbase = "/lidarr";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${defaults.mediaDir}/downloads 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.mediaDir}/music 0775 ${defaults.user} ${defaults.group} -"
    "d ${defaults.appdataDir}/lidarr/config 0755 ${defaults.user} ${defaults.group} -"
  ];
}