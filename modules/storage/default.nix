# modules/storage/default.nix 

{ config, lib, pkgs, ... }:

{  
  imports = [
    ./samba.nix
    ./vsftpd.nix
    # ./filemount.nix
    # ./rsync.nix
  ];

}