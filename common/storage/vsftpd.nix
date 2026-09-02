# common/storage/vsftpd.nix
{ config, ... }:
let
  defaults = import ../../settings;
  inherit (defaults) user;
in
{
  services.vsftpd = {
    enable = true;
    writeEnable = true;
    localUsers = true;
    userlist = [ user.name ];
    userlistEnable = true;
    extraConfig = ''
      pasv_enable=Yes
      pasv_min_port=51000
      pasv_max_port=51999
    '';
  };
}
