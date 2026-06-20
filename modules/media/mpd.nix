# modules/media/mpd.nix
{ config, pkgs, lib, ... }:

let
  defaults = import ../../lib;
in

{
  services.mpd = {
    enable = true;
    user = defaults.user;
    startWhenNeeded = true; 
    settings = {
      music_directory = "${defaults.dataDir}/music";
      audio_output = [
        {
          type = "pipewire";
          name = "PipeWire Output";
        }
      ];
    };
  };
  
  systemd.services.mpd.environment = {
    XDG_RUNTIME_DIR = "/run/user/1000"; 
  };  
}