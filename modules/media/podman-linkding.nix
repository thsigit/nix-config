# modules/media/podman-linkding.nix

{ config, ... }:

let
  defaults = import ../../settings;
  inherit (defaults) 
    user 
    directories;
  appdataDir = "${directories.appdata}/linkding";
in

{
  virtualisation.oci-containers.containers.linkding = {
    image = "sissbruecker/linkding:latest";
    ports = [ "9093:9090" ];
    volumes = [
      "${appdataDir}/data:/etc/linkding/data"
    ];
    environment = {
      # LD_SUPERUSER_NAME = "admin";
      # LD_SUPERUSER_PASSWORD = "password";
      LD_CONTEXT_PATH="linkding/";
    };
  };
  systemd.tmpfiles.rules = [
    "d ${appdataDir}/data 0755 ${user.name} ${user.group} -"
  ];
}
