# commons/core/boot.nix

{ config, lib, pkgs, ... }:

{
  # boot.uki.name = "UKI";
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 20;
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    timeout = 3;
  };

  # Tier-1 mitigation for "switch root target contains no usable init" (cold boot).
  # Stage-1 systemd gives up waiting for /dev/disk/by-uuid/* (root) after the
  # manager's default job timeout; slow AHCI link bring-up on cold boot can exceed it.
  # Extend the initrd manager timeout so stage-1 keeps waiting for the root device.
  boot.initrd.systemd.settings.Manager.DefaultTimeoutStartSec = "300s";
}
