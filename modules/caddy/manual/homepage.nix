{ config, lib, pkgs, ... }:

let
  defaults = import ../../../settings;
  inherit (defaults) tailnet domain;

  sslDir = "/etc/ssl/homelab";

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
  services.caddy.virtualHosts."homelab.${domain}" = {
    extraConfig = ''
      tls ${sslDir}/homelab.crt ${sslDir}/homelab.key
      ${homepageRouting}
    '';
  };

  services.caddy.virtualHosts."homelab.${tailnet}.ts.net" = {
    extraConfig = ''
      tls {
        get_certificate tailscale
      }
      ${homepageRouting}
    '';
  };
}
