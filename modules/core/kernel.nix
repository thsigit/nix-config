# modules/core/kernel.nix

{ config, lib, pkgs, ... }:
{
  # Kernel parameters & power‑management
  boot.kernelParams = [
    "quiet" "loglevel=3" "consoleblank=120" "acpi_osi=Linux"
    "ahci.mobile_lpm_policy=0"
  ];

  services.logind.settings.Login.HandleLidSwitch = "ignore";

  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };
}