# services/monitoring/darkstat.nix
{ config, lib, pkgs, ... }:
let cfg = config.services.darkstat; in
{
  options.services.darkstat = {
    enable = lib.mkEnableOption "darkstat";
    interface = lib.mkOption { type = lib.types.str; example = "enp0s31f6"; };
  };
  config = lib.mkIf cfg.enable {
    services.caddy.services.darkstat = { port = 667; visibility.tailscale = false; };
    services.darkstat.interface = lib.mkDefault "enp0s31f6";
    environment.systemPackages = [ pkgs.darkstat ];
    systemd.services.darkstat = {
      description = "Darkstat Traffic Monitor";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.darkstat}/bin/darkstat -i ${cfg.interface} --no-daemon";
        Restart = "on-failure";
      };
    };
  };
}
