# common/monitoring/mrtg.nix
# MRTG bandwidth polling (via net-snmp) + systemd timer. Polls localhost SNMP
# and writes HTML into ${www}/mrtg. Runs as the settings user.

{ config, pkgs, ... }:
let
  defaults = import ../../settings;
  inherit (defaults) user;
  inherit (defaults.directories) www;
  mrtgDir = "${www}/mrtg";
in
{
  services.snmpd = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 161;
    configText = ''
      rocommunity public 127.0.0.1
      syslocation Tamalate, Makassar
      syscontact ${user.name}@homelab
      sysname homelab
    '';
  };
  environment.systemPackages = with pkgs; [ mrtg net-snmp ];
  systemd.services.mrtg = {
    description = "MRTG polling";
    serviceConfig = { Type = "oneshot"; User = user.name; WorkingDirectory = mrtgDir; };
    script = "${pkgs.mrtg}/bin/mrtg ${mrtgDir}/mrtg.cfg";
  };
  systemd.timers.mrtg = {
    wantedBy = [ "timers.target" ];
    timerConfig = { OnBootSec = "1min"; OnUnitActiveSec = "5min"; };
  };
}
