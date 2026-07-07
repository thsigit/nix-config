# modules/ai/podman-localai.nix

{ config, pkgs, lib, ... }:

let
  defaults = import ../../lib;
  modelsDir = "/srv/ai/models";
in

{
  # Definisi container
  virtualisation.oci-containers.containers.localai = {
    image = "localai/localai:latest-cpu";
    ports = [ "8087:8080" ];
    volumes = [
      "${modelsDir}:/models"
      "${defaults.appdataDir}/localai/data:/data"
      "${defaults.appdataDir}/localai/configuration:/configuration"
    ];
    autoStart = true;
  };
  systemd.tmpfiles.rules = [
    "d /srv/ai 0755 ${defaults.user} ${defaults.group} -"
    "d /srv/ai/models 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.appdataDir}/localai 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.appdataDir}/localai/data 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.appdataDir}/localai/configuration 0755 ${defaults.user} ${defaults.group} -"
  ];
}