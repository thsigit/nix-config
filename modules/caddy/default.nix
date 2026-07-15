{ config, lib, pkgs, ... }:

let
  defaults = import ../../settings;
  inherit (defaults) tailnet domain;

  sslDir = "/etc/ssl/homelab";
  cfg = config.services.caddy;
  svcs = cfg.services;

  mkLANvhost = name: svc: {
    "${name}.${domain}".extraConfig = ''
      tls ${sslDir}/homelab.crt ${sslDir}/homelab.key
      reverse_proxy 127.0.0.1:${toString svc.port}
      ${lib.optionalString (svc.extraConfig != null) svc.extraConfig}
    '';
  };

  mkTailscalevhost = name: svc: {
    "${name}.${tailnet}.ts.net".extraConfig = ''
      tls {
        get_certificate tailscale
      }
      reverse_proxy 127.0.0.1:${toString svc.port}
      ${lib.optionalString (svc.extraConfig != null) svc.extraConfig}
    '';
  };

  generatedVhosts =
    lib.foldl' lib.recursiveUpdate { } (
      lib.mapAttrsToList (name: svc:
        (if svc.visibility.lan then mkLANvhost name svc else { })
        // (if svc.visibility.tailscale then mkTailscalevhost name svc else { })
      ) svcs
    );

in
{
  imports = [
    ./lib.nix
    ./manual
  ];

  services.caddy = {
    enable = true;
    virtualHosts = generatedVhosts;
  };

  systemd.tmpfiles.rules = [
    "d /var/log/caddy 0755 caddy caddy -"
  ];

  environment.systemPackages = with pkgs; [ caddy ];
}
