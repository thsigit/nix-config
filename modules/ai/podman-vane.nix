# modules/ai/podman-vane.nix
{ config, pkgs, lib, ... }:

let
  defaults = import ../../lib;
in
{
  virtualisation.oci-containers.containers.vane = {
    image = "itzcrazykns1337/vane:latest"; 
    ports = [ "8089:3000" ]; 
    volumes = [
      "${defaults.appdataDir}/vane/data:/home/vane/data"
    ];
    environment = defaults.baseEnv;
    autoStart = true;
  };

  systemd.tmpfiles.rules = [
    "d ${defaults.appdataDir}/vane 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.appdataDir}/vane/data 0755 ${defaults.user} ${defaults.group} -"
  ];
}