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

    handle /mrtg* {
      root * /srv/www
      file_server
    }

    handle /lidarr* {
      reverse_proxy 127.0.0.1:8686
    }
      
#    handle /calibre* {
#      uri strip_prefix /calibre
#      reverse_proxy 127.0.0.1:8083 {
#        #header_up Host {host}
#        #header_up X-Scheme {scheme}
#        header_up X-Script-Name /calibre
#      }
#    }
#  '';

in

{
  services.caddy = {
    enable = true;
    
    virtualHosts."homelab.home.arpa".extraConfig = ''
      tls /etc/ssl/homelab/homelab.crt /etc/ssl/homelab/homelab.key      
      # tls internal
      ${homepageConfig}
    '';

    virtualHosts."copyparty.home.arpa".extraConfig = ''
      tls /etc/ssl/homelab/homelab.crt /etc/ssl/homelab/homelab.key      
      reverse_proxy 127.0.0.1:3923
    '';

    virtualHosts."litellm.home.arpa".extraConfig = ''
      tls /etc/ssl/homelab/homelab.crt /etc/ssl/homelab/homelab.key      
      reverse_proxy 127.0.0.1:4000
    '';
	
    virtualHosts."vane.home.arpa".extraConfig = ''
      tls /etc/ssl/homelab/homelab.crt /etc/ssl/homelab/homelab.key      
      reverse_proxy 127.0.0.1:8089
    '';

    virtualHosts."triliumnotes.home.arpa".extraConfig = ''
      tls /etc/ssl/homelab/homelab.crt /etc/ssl/homelab/homelab.key      
      reverse_proxy 127.0.0.1:8088
    '';

    virtualHosts."localai.home.arpa".extraConfig = ''
      tls /etc/ssl/homelab/homelab.crt /etc/ssl/homelab/homelab.key      
      reverse_proxy 127.0.0.1:8087
    '';
    
    virtualHosts."calibre.home.arpa".extraConfig = ''
      tls /etc/ssl/homelab/homelab.crt /etc/ssl/homelab/homelab.key
      reverse_proxy 127.0.0.1:8083
    '';
	
    virtualHosts."navidrome.home.arpa".extraConfig = ''
      tls /etc/ssl/homelab/homelab.crt /etc/ssl/homelab/homelab.key      
      reverse_proxy 127.0.0.1:4533
    '';
	
    virtualHosts."linkding.home.arpa".extraConfig = ''
      tls /etc/ssl/homelab/homelab.crt /etc/ssl/homelab/homelab.key      
      reverse_proxy 127.0.0.1:9093
    '';
	
    virtualHosts."wallabag.home.arpa".extraConfig = ''
      tls /etc/ssl/homelab/homelab.crt /etc/ssl/homelab/homelab.key
      reverse_proxy 127.0.0.1:8085
    '';

    virtualHosts."darkstat.home.arpa".extraConfig = ''
      tls /etc/ssl/homelab/homelab.crt /etc/ssl/homelab/homelab.key
      reverse_proxy 127.0.0.1:667
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
