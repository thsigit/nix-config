{ config, pkgs, ... }:

let
  defaults = import ../../settings;
  inherit (defaults)
    user
    directories;
  appdataDir = "${directories.appdata}/copyparty";
in

{
  systemd.services.copyparty = {
    description = "Copyparty";

    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = user.name;
      Group = user.group;
      ExecStart =
        "${pkgs.copyparty}/bin/copyparty -c ${appdataDir}/copyparty.conf";

      Restart = "on-failure";
      RestartSec = 5;

      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";

      ReadWritePaths = [
        appdataDir
        "/home/${user.name}"
        "/etc/ssl"
        "/srv"
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d ${appdataDir} 0755 ${user.name} ${user.group} -"
  ];
}