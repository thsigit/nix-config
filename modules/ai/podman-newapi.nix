# modules/ai/podman-newapi.nix
{ config, pkgs, lib, ... }:

let
  defaults = import ../../lib;
in
{
  # Pastikan backend diset ke podman
  virtualisation.oci-containers.backend = "podman";

  virtualisation.oci-containers.containers.new-api = {
    image = "calciumion/new-api:latest"; # biarkan Caddy yang handle akses luar
    ports = [ "127.0.0.1:3000:3000" ]; 
    volumes = [
      "${defaults.appdataDir}/newapi/data:/data"
    ];
    environment = defaults.baseEnv;
    autoStart = true;
  };

  systemd.tmpfiles.rules = [
    "d ${defaults.appdataDir}/newapi 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.appdataDir}/newapi/data 0755 ${defaults.user} ${defaults.group} -"
  ];
}