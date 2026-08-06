# modules/media/bluetooth.nix 

{ config, ... }:

{
  hardware.bluetooth = {
    enable = true;
    # settings = {
    #  General = {
    #    Enable = "Source,Sink,Media,Control";
    #  };
    # };
  };
}