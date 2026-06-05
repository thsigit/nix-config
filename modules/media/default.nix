# modules/media/default.nix 

{ config, lib, pkgs, ... }:

{  
  # PipeWire audio control
  security.rtkit.enable = true; 
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Activate Bluetooth 
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
}