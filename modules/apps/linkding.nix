# modules/apps/linkding.nix

{ config, pkgs, lib, ... }:

let
  defaults = import ../../lib;
in

{
  virtualisation.oci-containers.containers.linkding = {
    image = "sissbruecker/linkding:latest";
    ports = [ "9093:9090" ];
    volumes = [
      "${defaults.appDir}/linkding/data:/etc/linkding/data"
    ];
    environment = {
      # LD_SUPERUSER_NAME = "admin";
      # LD_SUPERUSER_PASSWORD = "password";
      LD_CONTEXT_PATH="linkding/";
    };
  };
  systemd.tmpfiles.rules = [
    "d ${defaults.appDir}/linkding/data 0755 ${defaults.user} ${defaults.group} -"
  ];
}
