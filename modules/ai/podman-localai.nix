# modules/ai/podman-localai.nix

{ config, pkgs, lib, ... }:

let
  defaults = import ../../settings;
  inherit (defaults) user ai;
  inherit (defaults.directories) appdata;

  appdataDir = "${appdata}/localai";
in

{
  services.caddy.services.localai = {
    port = 8087;
  };

  virtualisation.oci-containers.containers.localai = {
    image = "localai/localai:latest-cpu";
    ports = [ "8087:8080" ];
    volumes = [
      "${ai.models}:/models"
      "${appdataDir}/data:/data"
      "${appdataDir}/configuration:/configuration"
    ];

    autoStart = true;
  };

  systemd.tmpfiles.rules = [
    "d ${ai.root} 0755 ${user.name} ${user.group} -"
    "d ${ai.models} 0755 ${user.name} ${user.group} -"
    "d ${appdataDir} 0755 ${user.name} ${user.group} -"
    "d ${appdataDir}/data 0755 ${user.name} ${user.group} -"
    "d ${appdataDir}/configuration 0755 ${user.name} ${user.group} -"
  ];
}
