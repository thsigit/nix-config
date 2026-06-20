# modules/media/qbittorrent.nix

{ config, pkgs, lib, ... }:

let
  defaults = import ../../lib;
in

{
  virtualisation.oci-containers.containers.qbittorrent = {
    image = "lscr.io/linuxserver/qbittorrent:latest";
    environment = {
      PUID = "1000";
      PGID = "100";
      TZ = "Asia/Jakarta";
      WEBUI_PORT = "8080";
      # Proxy instructions
      #PROXY_TYPE = "SOCKS5";
      #PROXY_ADDR = "socks5-proxy:1080"; # Nama container ini
      #PROXY_USER = "user";
      #PROXY_PASS = "pass";
      #PROXY_PEER_CONN = "true";
      #PROXY_HOSTNAME_LOOKUP = "true";
    };
    # ports = [ "127.0.0.1:8080:8080" ];
    # dependsOn = [ "socks5-proxy" ];
    ports = [
      "127.0.0.1:8080:8080"   # Web UI
      "51411:51411"             # BitTorrent TCP
      "51411:51411/udp"         # BitTorrent UDP
    ];
    volumes = [
      "${defaults.appDir}/qbittorrent/config:/config"
      "${defaults.dataDir}/qbittorrent_downloads:/downloads"
    ];
    autoStart = true;
  };

  systemd.tmpfiles.rules = [
    "d ${defaults.appDir}/qbittorrent 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.appDir}/qbittorrent/config 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.dataDir}/qbittorrent_downloads 0755 ${defaults.user} ${defaults.group} -"
  ];
}
