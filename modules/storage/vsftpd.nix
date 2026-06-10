# modules/storage/vsftpd.nix 

{ config, lib, pkgs, ... }:

{
  # FTP Server
  services.vsftpd = {
    enable = true;
    writeEnable = true;
    localUsers = true;
    userlist = [ "sigit" ];
    userlistEnable = true;
    extraConfig = ''
      pasv_enable=Yes
      pasv_min_port=51000
      pasv_max_port=51999
    '';
  };

}