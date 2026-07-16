{ config, lib, pkgs, ... }:

let
  defaults = import ../../settings;
  inherit (defaults) domain tailnet;
  port = 3000;
in

{
  services.caddy.services.opencode = {
    inherit port;
    visibility = {
      lan = true;
      tailscale = true;
    };
    extraConfig = null;
  };

  systemd.services.opencode = {
    description = "opencode headless server";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.opencode}/bin/opencode serve \
        --hostname 127.0.0.1 \
        --port ${toString port} \
        --cors *.${domain} \
        --cors *.${tailnet}.ts.net";
      Restart = "on-failure";
      RestartSec = "5s";
      DynamicUser = true;
      StateDirectory = "opencode";
    };
  };

  environment.systemPackages = [ pkgs.opencode ];
}
