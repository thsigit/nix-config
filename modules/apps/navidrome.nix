# modules/apps/navidrome.nix

{ config, pkgs, lib, ... }:

let
  defaults = import ../../lib;
in

{
  services.navidrome = {
    enable = true;
    # Secara default NixOS menjalankan ini dengan user/group "navidrome".
    # Kita timpa agar menggunakan user/group Anda agar sinkron dengan Lidarr & rsync.
    user = defaults.user;
    group = defaults.group;
    
    settings = {
      # Menentukan lokasi database, cache, dll
      DataFolder = "${defaults.appDir}/navidrome/data";
      
      # Menentukan lokasi library musik (sama dengan Lidarr)
      MusicFolder = "${defaults.dataDir}/music";
      
      # Konfigurasi environment dari podman lama
      ScanSchedule = "1h";
      LogLevel = "info";
      SessionTimeout = "24h";
      BaseUrl = "/navidrome";
      
      # Mengunci port internal (tidak membuka firewall secara otomatis)
      Address = "127.0.0.1";
      Port = 4533;
    };
  };

  # Pertahankan aturan tmpfiles untuk memastikan hak akses direktori
  systemd.tmpfiles.rules = [
    "d ${defaults.dataDir}/music 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.appDir}/navidrome/data 0755 ${defaults.user} ${defaults.group} -"
  ];
}