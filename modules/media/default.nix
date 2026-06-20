# modules/media/default.nix 

{ config, lib, pkgs, ... }:

{  
  imports = [
    ./calibre-web.nix
    # ./lidarr.nix
    ./linkding.nix
    ./mpd.nix
    ./navidrome.nix
    # ./qbittorrent.nix
    # ./transmission.nix
    ./wallabag.nix
  ];

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
