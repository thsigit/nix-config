# modules/media/qbittorrent.nix

{ config, ... }:

let
  defaults = import ../../settings;
  inherit (defaults) 
    user 
    directories 
    baseEnv;
  appdataDir = "${directories.appdata}/qbittorrent";
  mediaRoot = directories.media;
in

{
  virtualisation.oci-containers.containers.qbittorrent = {
    image = "lscr.io/linuxserver/qbittorrent:latest";
    environment = baseEnv // {
      WEBUI_PORT = "8080";
    
      # Proxy instructions
      # PROXY_TYPE = "SOCKS5";
      # PROXY_ADDR = "socks5-proxy:1080";
      # PROXY_USER = "user";
      # PROXY_PASS = "pass";
      # PROXY_PEER_CONN = "true";
      # PROXY_HOSTNAME_LOOKUP = "true";
    };
    # ports = [ "127.0.0.1:8080:8080" ];
    # dependsOn = [ "socks5-proxy" ];
    ports = [
      "127.0.0.1:8080:8080"   # Web UI
      "51411:51411"             # BitTorrent TCP
      "51411:51411/udp"         # BitTorrent UDP
    ];
    volumes = [
      "${appdataDir}/config:/config"
      "${mediaRoot}/qbittorrent_downloads:/downloads"
    ];
    autoStart = true;
  };

  systemd.tmpfiles.rules = [
    "d ${appdataDir} 0755 ${user.name} ${user.group} -"
    "d ${appdataDir}/config 0755 ${user.name} ${user.group} -"
    "d ${mediaRoot}/qbittorrent_downloads 0755 ${user.name} ${user.group} -"
  ];
}
