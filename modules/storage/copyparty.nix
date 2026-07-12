{ config, lib, pkgs, ... }:

let
  defaults = import ../../lib;
in

{
  users.users.copyparty = {
    isSystemUser = true;
    group = "copyparty";
    home = "${defaults.appdataDir}/copyparty";
  };

  users.groups.copyparty = {};

  systemd.tmpfiles.rules = [
    "d ${defaults.appdataDir}/copyparty 0755 copyparty copyparty -"
  ];

  systemd.services.copyparty = {
    description = "Copyparty";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";

      User = "copyparty";
      Group = "copyparty";
      WorkingDirectory = "${defaults.appdataDir}/copyparty";

      ExecStart =
        "${pkgs.copyparty}/bin/copyparty -c ${defaults.appdataDir}/copyparty/copyparty.conf";

      Restart = "on-failure";
      RestartSec = 5;

      # Hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ReadWritePaths = [
        "${defaults.appdataDir}/copyparty"
      ];
    };
  };
}