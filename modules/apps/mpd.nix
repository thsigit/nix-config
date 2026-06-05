# services/mpd.nix
{ config, pkgs, lib, ... }:

{
  services.mpd = {
    enable = true;
    user = "sigit";
    musicDirectory = "/srv/data/music";
    extraConfig = ''
      audio_buffer_size "16384"
      buffer_before_play "20%"
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