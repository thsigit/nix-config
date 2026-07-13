# modules/storage/default.nix 

{  
  imports = [
    ./samba.nix
    ./vsftpd.nix
    ./copyparty.nix
    # ./filemount.nix
    # ./rsync.nix
  ];

}