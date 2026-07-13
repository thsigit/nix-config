# modules/media/pulseaudio.nix 

{ config ... }:

{
  services.pulseaudio = {
    enable = true;
    support32Bit = true;
    package = pkgs.pulseaudioFull;
    systemWide = false;   # Run per-user (recommended)
    extraConfig = ''
      default-sample-rate = 48000
      resample-method = speex-float-5
      default-fragments = 4
      default-fragment-size-msec = 25
      realtime-priority = 5
      nice-level = -11
    '';
  };
}