# commons/storage/default.nix
{ ... }:
{
  imports = [
    ./samba.nix
    ./vsftpd.nix
    ./copyparty.nix
  ];
}
