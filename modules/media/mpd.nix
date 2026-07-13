# modules/media/mpd.nix

{ config, ... }:

let
  defaults = import ../../settings;
  inherit (defaults) 
    user 
    directories;
in

{
  services.mpd = {
    enable = true;
    user = user.name;
    startWhenNeeded = true;
    settings = {
      music_directory = "${directories.media}/music";
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