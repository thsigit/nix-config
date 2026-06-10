# modules/monitoring/darkstat.nix

{ config, lib, pkgs, ... }:

let
  cfg = config.services.darkstat;
in
{
  options.services.darkstat = {
    enable = lib.mkEnableOption "darkstat";
    interface = lib.mkOption {
      type = lib.types.str;
      example = "enp0s31f6";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.darkstat ];

    systemd.services.darkstat = {
      description = "Darkstat Traffic Monitor";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        # Use simple type and pass --no-daemon to prevent systemd timing out
        Type = "simple";
        ExecStart = "${pkgs.darkstat}/bin/darkstat -i ${cfg.interface} --no-daemon";
        Restart = "on-failure";
      };
    };
  };
}
