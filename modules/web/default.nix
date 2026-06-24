# modules/app/web/default.nix
{ config, lib, pkgs, ... }:

let
  homepageConfig = ''

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
  
    handle_path /glossopetrae* {
      root * /srv/www/glossopetrae
      try_files {path} /index.html
      file_server
    }

    handle_path /mrtg* {
      root * /srv/www
      file_server
    }

    handle /linkding* {
      reverse_proxy 127.0.0.1:9093
    }

    handle /lidarr* {
      reverse_proxy 127.0.0.1:8686
    }

    handle /navidrome* {
      reverse_proxy 127.0.0.1:4533
    }
      
    handle /calibre* {
      uri strip_prefix /calibre
      reverse_proxy 127.0.0.1:8083 {
        #header_up Host {host}
        #header_up X-Scheme {scheme}
        header_up X-Script-Name /calibre
      }
    }
  '';

in

{
  services.caddy = {
    enable = true;
    
    virtualHosts."homelab.home.arpa".extraConfig = ''
      tls /etc/ssl/homelab/homelab.crt /etc/ssl/homelab/homelab.key      
      ${homepageConfig}
    '';
    
    virtualHosts."wallabag.home.arpa".extraConfig = ''
      tls /etc/ssl/homelab/homelab.crt /etc/ssl/homelab/homelab.key
      reverse_proxy 127.0.0.1:8085
    '';

    virtualHosts."darkstat.home.arpa".extraConfig = ''
      reverse_proxy 127.0.0.1:667
      tls /etc/ssl/homelab/homelab.crt /etc/ssl/homelab/homelab.key
    '';

    virtualHosts."homelab.basa-komodo.ts.net".extraConfig = ''
      tls {
        get_certificate tailscale
      }
      ${homepageConfig}
     '';
  };
  
  systemd.tmpfiles.rules = [
    "d /var/log/caddy 0755 caddy caddy -"
  ];  
  
  environment.systemPackages = with pkgs; [
    caddy
  ];

}
