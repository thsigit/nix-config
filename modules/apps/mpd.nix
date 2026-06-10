# services/mpd.nix
{ config, pkgs, lib, ... }:

let
  defaults = import ../../lib;
in

{
  services.mpd = {
    enable = true;
    user = defaults.user;
    musicDirectory = "${defaults.dataDir}/music";
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