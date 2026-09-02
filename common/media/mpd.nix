# common/media/mpd.nix
# MPD daemon — enable + config. Local concern: run as the settings user and
# point XDG_RUNTIME_DIR at that user's runtime dir (PipeWire per-user socket).

{ config, ... }:
let
  defaults = import ../../settings;
  inherit (defaults) user;
  inherit (defaults.directories) media;
in
{
  services.mpd = {
    enable = true;
    user = user.name;
    startWhenNeeded = true;
    settings = {
      music_directory = "${media}/music";
      audio_output = [{ type = "pipewire"; name = "PipeWire Output"; }];
    };
  };
  systemd.services.mpd.environment.XDG_RUNTIME_DIR = "/run/user/${user.uid}";
}
