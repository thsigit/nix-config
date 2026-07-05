# modules/security/sops.nix
{ pkgs, ... }:

{
  sops = {
    age.keyFile = "/var/lib/sops-nix/key.txt"; 
  };

  environment.systemPackages = with pkgs; [
    sops
    age
    ssh-to-age
  ];
}