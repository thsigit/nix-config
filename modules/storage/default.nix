# modules/storage/default.nix 

{ config, lib, pkgs, ... }:

{  
  imports = [
    ./rsync.nix
    ./samba.nix
    ./vsftpd.nix
    ./filemount.nix
  ];
  
  # services.udev.extraRules = ''
  # Matikan SSD PNY rusak secara permanen menggunakan Serial Number uniknya
  #  SUBSYSTEM=="block", ENV{ID_SERIAL}=="PNY_CS900_240GB_SSD_PNY4320025935021219C", ATTR{device/delete}="1"
  # '';  
}