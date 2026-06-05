# modules/storage/filemount.nix 

{ config, lib, pkgs, ... }:

{
  # Mount secondary SSD
  fileSystems."/mnt/datadisk" = {
    device = "/dev/disk/by-uuid/CE16B4C516B4AFB7";
    fsType = "ntfs";
    options = [ 
      "users" "noauto" "nofail" "rw" "nodev" "nosuid" "exec" "noatime"
      "x-systemd.automount"
      "x-systemd.idle-timeout=300"
    ];
  };
}