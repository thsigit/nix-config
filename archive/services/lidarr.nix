/*
 * Status: Archived
 * Last used: 2026-07
 * Reason: Not currently needed; reusable Lidarr music management service
 * Safe to delete after: 2026-10
 */

# modules/media/lidarr.nix

{ config, pkgs, lib, ... }:

let
  defaults = import ../../settings;
  inherit (defaults) 
    user 
    directories;
  appdataDir = "${directories.appdata}/lidarr";
  mediaRoot = directories.media;
in

{
  services.lidarr = {
    enable = true;
    user = user.name;
    group = user.group;
    dataDir = "${appdataDir}/config";
    settings = {
      server = {
      port = 8686;
      urlbase = "/lidarr";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${mediaRoot} 0755 ${user.name} ${user.group} -"
    "d ${mediaRoot}/downloads 0755 ${user.name} ${user.group} -"
    "d ${mediaRoot}/music 0775 ${user.name} ${user.group} -"
    "d ${appdataDir}/config 0755 ${user.name} ${user.group} -"
  ];
}