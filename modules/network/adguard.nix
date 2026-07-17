# modules/network/adguard.nix

{ config, pkgs, lib, ... }:

let
  defaults = import ../../settings;
  inherit (defaults) user;
  inherit (defaults.directories) appdata;

  appdataDir = "${appdata}/adguard";
in

{
  virtualisation.oci-containers.containers.adguard = {
    image = "adguard/adguardhome:latest";
    ports = [ "3000:3000" "53:53/tcp" "53:53/udp" ];
    volumes = [
      "${appdataDir}/conf:/opt/adguardhome/conf"
      "${appdataDir}/work:/opt/adguardhome/work"
    ];
  };

  systemd.tmpfiles.rules = [
    "d ${appdataDir}/work 0775 ${user.name} ${user.group} -"
    "d ${appdataDir}/conf 0755 ${user.name} ${user.group} -"
  ];
}
