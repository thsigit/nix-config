# modules/media/pipewire.nix 

{ config, ... }:

{
  # PipeWire audio control
  security.rtkit.enable = true; 
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}