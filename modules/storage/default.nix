# modules/storage/default.nix 

{ config, lib, pkgs, ... }:

{  
  imports = [
    # ./rsync.nix
    ./samba.nix
    ./vsftpd.nix
    ./filemount.nix
  ];

}