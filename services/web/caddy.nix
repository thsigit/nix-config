# services/web/caddy.nix
# Caddy reverse proxy with lib + homepage routing.

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
      tls { get_certificate tailscale }
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

  homepageRouting = ''
    handle {
      root * /srv/www/homepage
      file_server
      encode gzip zstd
    }
    handle_path /godmod3* {
      root * /srv/www/godmod3
      file_server
      encode gzip zstd
    }
    handle_path /freegpt* {
      root * /srv/www/freegpt
      file_server
      encode gzip zstd
    }
    redir /glossopetrae /glossopetrae/ 308
    handle_path /glossopetrae* {
      root * /srv/www/glossopetrae
      try_files {path} /index.html
      file_server
      encode gzip zstd
    }
    handle /mrtg* {
      root * /srv/www
      file_server
    }
    handle /lidarr* {
      reverse_proxy 127.0.0.1:8686
    }
  '';
in

{
  options.services.caddy.services = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
      options = {
        port = lib.mkOption { type = lib.types.port; };
        visibility = {
          lan = lib.mkOption { type = lib.types.bool; default = true; };
          tailscale = lib.mkOption { type = lib.types.bool; default = true; };
        };
        extraConfig = lib.mkOption { type = lib.types.nullOr lib.types.lines; default = null; };
      };
    }));
    default = { };
  };

  config = {
    services.caddy = {
      enable = true;
      virtualHosts = generatedVhosts // {
        "homelab.${domain}".extraConfig = ''
          tls ${sslDir}/homelab.crt ${sslDir}/homelab.key
          ${homepageRouting}
        '';
        "homelab.${tailnet}.ts.net".extraConfig = ''
          tls { get_certificate tailscale }
          ${homepageRouting}
        '';
      };
    };
    systemd.tmpfiles.rules = [ "d /var/log/caddy 0755 caddy caddy -" ];
    environment.systemPackages = [ pkgs.caddy ];
  };
}
