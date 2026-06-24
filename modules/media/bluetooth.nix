# modules/media/bluetooth.nix 

{ config, lib, pkgs, ... }:

{
  hardware.bluetooth = {
    enable = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Control";
      };
    };
  };
}