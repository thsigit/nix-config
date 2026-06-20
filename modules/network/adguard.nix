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
      "${defaults.appDir}/adguard/work:/opt/adguardhome/work"
      "${defaults.appDir}/adguard/conf:/opt/adguardhome/conf"
    ];
  };
  systemd.tmpfiles.rules = [
    "d ${defaults.appDir}/adguard/work 0775 ${defaults.user} ${defaults.group} -"
    "d ${defaults.appDir}/adguard/conf 0755 ${defaults.user} ${defaults.group} -"
  ];
}

