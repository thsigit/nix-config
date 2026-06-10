# modules/apps/lidarr.nix

{ config, pkgs, lib, ... }:

let
  defaults = import ../../lib;
in

{
  services.lidarr = {
    enable = true;
    user = defaults.user;
    group = defaults.group;
    dataDir = "${defaults.appDir}/lidarr/config";
    settings = {
      server = {
	    port = 8686;
	    urlbase = "/lidarr";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${defaults.dataDir}/downloads 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.dataDir}/music 0775 ${defaults.user} ${defaults.group} -"
    "d ${defaults.appDir}/lidarr/config 0755 ${defaults.user} ${defaults.group} -"
  ];
}