# modules/monitoring/mrtg.nix

{ config, pkgs, lib, ... }:

{
  services.snmpd = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 161;
    configText = ''
      rocommunity public 127.0.0.1
      syslocation Tamalate, Makassar
      syscontact sigit@homelab
      sysname homelab
    '';
  };

  environment.systemPackages = with pkgs; [
    mrtg
    net-snmp
  ];

  systemd.services.mrtg = {
    description = "MRTG polling";

    serviceConfig = {
      Type = "oneshot";
      User = "sigit";
      WorkingDirectory = "/var/www/mrtg";
    };

    script = ''
      ${pkgs.mrtg}/bin/mrtg /var/www/mrtg/mrtg.cfg
    '';
  };

  systemd.timers.mrtg = {
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "5min";
    };
  };

}
