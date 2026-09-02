# system/power.nix
# Power/cpu governor. Machine-specific performance tuning (paired with TLP).

{ config, lib, pkgs, ... }:
{
  powerManagement.cpuFreqGovernor = "performance";
}
