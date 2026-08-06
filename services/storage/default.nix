# services/storage/default.nix
{ ... }:
{
  imports = [
    ./samba.nix
    ./vsftpd.nix
    ./copyparty.nix
  ];
}
