# modules/core/boot.nix

{ config, lib, pkgs, ... }:

{
  # boot.uki.name = "UKI";
  boot.loader = {
    systemd-boot = {
      enable = false;
      configurationLimit = 20;
    };
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      gfxmodeEfi = "text";
      configurationLimit = 20;
      useOSProber = false;
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    timeout = 3;
  };
}
