# programs/hardware.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    lshw lsof smartmontools lm_sensors libinput evtest pciutils fetchutils usbutils
    parted gptfdisk efibootmgr dmidecode psmisc
  ];
}
