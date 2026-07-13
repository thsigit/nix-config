# modules/security/sops.nix

{ config, pkgs, ... }:

{
  sops = {
    age.keyFile = "/home/sigit/.config/sops/age/keys.txt";
  };

  sops.secrets."providers.env" = {
    sopsFile = ../../secrets/providers.env;
    format = "dotenv";
  };

  environment.systemPackages = with pkgs; [
    sops
    age
    ssh-to-age
  ];
}