# modules/storage/filemount.nix 

{ config, lib, pkgs, ... }:

{
  # mount /dev/sda1 as srv
  fileSystems."/srv" = {
    device = "/dev/disk/by-uuid/6369bfa1-6c53-4a13-8afc-e873a00ddf33";
    fsType = "ext4";
    options = [ "defaults" "noatime" ];
  };
}
