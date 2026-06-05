# modules/apps/security/ssh.nix
{ config, pkgs, lib, ... }:

{
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false; # Wajib pakai SSH Key, matikan password
      PermitRootLogin = "no";         # Larang root masuk langsung
    };
  };

  # ==========================================
  # REGISTRASI SSH KEY USER (DEKLARATIF)
  # ==========================================
  users.users.sigit = {
    openssh.authorizedKeys.keys = [
      (builtins.readFile ../../secrets/ssh_key_V2333.txt)
      (builtins.readFile ../../secrets/ssh_key_Lenovo.txt)
      (builtins.readFile ../../secrets/ssh_key_UbuntuWSL.txt)
    ];
  };
}