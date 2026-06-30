# modules/media/transmission.nix
{ config, pkgs, lib, ... }:

let
  defaults = import ../../lib;
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
      "${defaults.appdataDir}/transmission/config:/config:Z"
      "${defaults.mediaDir}/transmission_downloads:/downloads:Z"
      "${defaults.mediaDir}/transmission_watch:/watch:Z"
    ];
    
    environment = defaults.baseEnv;   
    autoStart = true;
  };

  systemd.tmpfiles.rules = [
    "d ${defaults.appdataDir}/transmission 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.appdataDir}/transmission/config 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.mediaDir}/transmission_downloads 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.mediaDir}/transmission_watch 0755 ${defaults.user} ${defaults.group} -"
  ];
}
