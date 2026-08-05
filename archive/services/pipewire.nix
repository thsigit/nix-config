/*
 * Status: Archived
 * Last used: 2026-07
 * Reason: PipeWire not currently enabled; standard NixOS boilerplate config
 * Safe to delete after: 2026-10
 */

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