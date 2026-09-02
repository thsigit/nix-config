# common/ai/opencode.nix
# opencode headless server — enable + config only.

{ config, lib, pkgs, ... }:

let
  defaults = import ../../settings;
  inherit (defaults) user domain tailnet;
  inherit (defaults.directories) appdata;
  port = 3000;
in
{
  services.caddy.services.opencode = {
    inherit port;
    visibility = { lan = true; tailscale = true; };
    extraConfig = null;
  };

  systemd.services.opencode = {
    description = "opencode headless server";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.opencode}/bin/opencode serve --hostname 127.0.0.1 --port ${toString port} --cors *.${domain} --cors *.${tailnet}.ts.net";
      Restart = "on-failure";
      RestartSec = "5s";
      User = user.name;
      Group = user.group;
      StateDirectory = "opencode";
      StateDirectoryMode = "0755";
    };
    environment.HOME = "${appdata}/opencode";
  };

  systemd.tmpfiles.rules = [
    "d ${appdata}/opencode 0755 ${user.name} ${user.group} -"
  ];

  environment.systemPackages = [ pkgs.opencode ];
}
