# commons/ai/vane-container.nix
# Vane (SearXNG-based) — container runtime + config only.

{ config, pkgs, lib, ... }:

let
  defaults = import ../../settings;
  inherit (defaults) user baseEnv;
  inherit (defaults.directories) appdata;
  appdataDir = "${appdata}/vane";
in
{
  services.caddy.services.vane = { port = 8089; };

  virtualisation.oci-containers.containers.vane = {
    image = "itzcrazykns1337/vane:latest";
    ports = [ "8089:3000" ];
    volumes = [
      "${appdataDir}/data:/home/vane/data"
      "${appdataDir}/searxng:/etc/searxng"
    ];
    environment = baseEnv;
    autoStart = true;
  };

  systemd.tmpfiles.rules = [
    "d ${appdataDir} 0755 ${user.name} ${user.group} -"
    "d ${appdataDir}/data 0755 ${user.name} ${user.group} -"
    "d ${appdataDir}/searxng 0755 ${user.name} ${user.group} -"
  ];
}
