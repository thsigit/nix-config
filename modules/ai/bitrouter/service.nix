# modules/ai/bitrouter/service.nix
# Native (systemd) run mode — runs the bitrouter package directly.
#
# Active only when services.bitrouter.mode == "native".

{ config, pkgs, lib, ... }:

let
  cfg = config.services.bitrouter;
in

{
  config = lib.mkIf (cfg.enable && cfg.mode == "native") {
    systemd.services.bitrouter = {
      description = "BitRouter LLM gateway (native)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      environmentFiles = cfg.environmentFiles;

      serviceConfig = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/bitrouter serve -c ${cfg.configFile}";
        WorkingDirectory = cfg.stateDir;
        Restart = "on-failure";
        RestartSec = "3";
      };
    };

    # Reverse proxy: bitrouter.home.arpa -> 127.0.0.1:<port>
    services.caddy.services.bitrouter = {
      port = cfg.port;
    };

    # Bind a unix control socket in the state dir (server.control_socket).
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
