# commons/security/sops.nix

{ config, pkgs, ... }:

{
  sops = {
    age.keyFile = "/home/sigit/.config/sops/age/keys.txt";
  };

  sops.secrets."litellm.env" = {
    sopsFile = ../secrets/litellm.env;
    format = "dotenv";
  };

  sops.secrets."providers.env" = {
    sopsFile = ../secrets/providers.env;
    format = "dotenv";
    owner = "sigit";
    group = "users";
    mode = "0440";
  };

  environment.systemPackages = with pkgs; [
    sops
    age
    ssh-to-age
  ];
}
