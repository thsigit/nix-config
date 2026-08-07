# modules/media/linkding-container.nix
# Linkding (self-hosted bookmark manager) — container runtime + config.

{ config, ... }:
let
  defaults = import ../../settings;
  inherit (defaults) user;
  inherit (defaults.directories) appdata;
  appdataDir = "${appdata}/linkding";
in
{
  services.caddy.services.linkding = { port = 9093; };
  virtualisation.oci-containers.containers.linkding = {
    image = "sissbruecker/linkding:latest";
    ports = [ "9093:9090" ];
    volumes = [ "${appdataDir}/data:/etc/linkding/data" ];
  };
  systemd.tmpfiles.rules = [ "d ${appdataDir}/data 0755 ${user.name} ${user.group} -" ];
}
