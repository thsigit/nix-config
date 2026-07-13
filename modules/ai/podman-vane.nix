# modules/ai/podman-vane.nix
{ config, pkgs, lib, ... }:

let
  defaults = import ../../settings;
  inherit (defaults) 
    user 
    directories 
    baseEnv;
  appdataDir = "${directories.appdata}/vane";
in

{
  virtualisation.oci-containers.containers.vane = {
    image = "itzcrazykns1337/vane:latest";
    ports = [ "8089:3000" ];
    volumes = [
      "${appdataDir}/data:/home/vane/data"
    ];
    environment = baseEnv;
    autoStart = true;
  };

  systemd.tmpfiles.rules = [
    "d ${appdataDir} 0755 ${user.name} ${user.group} -"
    "d ${appdataDir}/data 0755 ${user.name} ${user.group} -"
  ];
}