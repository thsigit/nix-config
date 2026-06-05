# services/mpd.nix
{ config, pkgs, lib, ... }:

{
  # Mengaktifkan layanan MPD bawaan NixOS
  services.mpd = {
    enable = true;
    user = "sigit";
    musicDirectory = "/srv/data/music";
    extraConfig = ''

      # Alokasikan buffer lebih besar agar tidak sering menyentuh disk
      audio_buffer_size "16384"
      buffer_before_play "20%"
    
      # Matikan auto-update jika Lidarr sering mengubah isi folder
      auto_update "no"
	
      audio_output {
        type "pipewire"
        name "PipeWire Output"
      }
    '';
  };
  
  systemd.services.mpd.environment = {
    XDG_RUNTIME_DIR = "/run/user/1000"; 
  };
  
}