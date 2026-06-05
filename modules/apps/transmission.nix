# containers/transmission.nix
{ config, pkgs, lib, ... }:

let
  defaults = import ../lib
in

{
  virtualisation.oci-containers.containers.transmission = {
    image = "lscr.io/linuxserver/transmission:latest";
    # PENTING: Gunakan user root agar bisa menulis ke volume.
    # Di Podman rootless, `--user root` tetap aman karena container tetap berjalan
    # sebagai user host Anda (UID 1000).
    #extraArgs = [ "--user=root" ];
    
    ports = [
      "127.0.0.1:9091:9091"   # Web UI Transmission
      "51413:51413"           # Port untuk koneksi peer (TCP)
      "51413:51413/udp"       # Port untuk koneksi peer (UDP)
    ];
    
    volumes = [
      "${defaults.appDir}/transmission/config:/config:Z"     # Untuk menyimpan setting dan state
      "${defaults.dataDir}/transmission_downloads:/downloads:Z" # Tempat file unduhan
      "${defaults.dataDir}/transmission_watch:/watch:Z"      # Folder watch untuk file .torrent
    ];
    
    environment = defaults.transmissionEnv;   
    autoStart = true;
  };
  
  # Opsional: Buat direktori yang diperlukan
  systemd.tmpfiles.rules = [
    "d ${defaults.appDir}/transmission 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.appDir}/transmission/config 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.dataDir}/transmission_downloads 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.dataDir}/transmission_watch 0755 ${defaults.user} ${defaults.group} -"
  ];
}
