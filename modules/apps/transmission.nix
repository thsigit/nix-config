# modules/apps/transmission.nix
{ config, pkgs, lib, ... }:

let
  defaults = import ../lib
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
      "${defaults.appDir}/transmission/config:/config:Z"
      "${defaults.dataDir}/transmission_downloads:/downloads:Z"
      "${defaults.dataDir}/transmission_watch:/watch:Z"
    ];
    
    environment = defaults.transmissionEnv;   
    autoStart = true;
  };

  systemd.tmpfiles.rules = [
    "d ${defaults.appDir}/transmission 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.appDir}/transmission/config 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.dataDir}/transmission_downloads 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.dataDir}/transmission_watch 0755 ${defaults.user} ${defaults.group} -"
  ];
}
