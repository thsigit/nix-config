# modules/media/transmission.nix
{ config, pkgs, lib, ... }:

let
  defaults = import ../../settings;
  inherit (defaults) 
    user 
    directories 
    baseEnv;
  appdataDir = "${directories.appdata}/transmission";
  mediaRoot = directories.media;
in

{
  virtualisation.oci-containers.containers.transmission = {
    image = "lscr.io/linuxserver/transmission:latest";
    ports = [
      "127.0.0.1:9091:9091"
      "51413:51413"
      "51413:51413/udp"
    ];

    volumes = [
      "${appdataDir}/config:/config:Z"
      "${mediaRoot}/transmission_downloads:/downloads:Z"
      "${mediaRoot}/transmission_watch:/watch:Z"
    ];

    environment = baseEnv;
    autoStart = true;
  };

  systemd.tmpfiles.rules = [
    "d ${appdataDir} 0755 ${user.name} ${user.group} -"
    "d ${appdataDir}/config 0755 ${user.name} ${user.group} -"
    "d ${mediaRoot}/transmission_downloads 0755 ${user.name} ${user.group} -"
    "d ${mediaRoot}/transmission_watch 0755 ${user.name} ${user.group} -"
  ];
}
