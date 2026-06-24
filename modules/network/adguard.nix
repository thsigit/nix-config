# modules/network/adguard.nix

{ config, pkgs, lib, ... }:

let
  defaults = import ../../lib;
in

{
  virtualisation.oci-containers.containers.adguard = {
    image = "adguard/adguardhome:latest";
    ports = [ "3000:3000" "53:53/tcp" "53:53/udp" ];
    volumes = [
      "${defaults.appdataDir}/adguard/work:/opt/adguardhome/work"
      "${defaults.appdataDir}/adguard/conf:/opt/adguardhome/conf"
    ];
  };
  systemd.tmpfiles.rules = [
    "d ${defaults.appdataDir}/adguard/work 0775 ${defaults.user} ${defaults.group} -"
    "d ${defaults.appdataDir}/adguard/conf 0755 ${defaults.user} ${defaults.group} -"
  ];
}

