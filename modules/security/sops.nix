# modules/security/sops.nix

{ config, pkgs, ... }:

{
  sops = {
    age.keyFile = "/home/sigit/.config/sops/age/keys.txt";
  };

  sops.secrets."litellm.yaml" = {
    sopsFile = ../../secrets/litellm.yaml;
    format = "yaml";
  };

  sops.secrets."providers.yaml" = {
    sopsFile = ../../secrets/providers.yaml;
    format = "yaml";
  };

  environment.systemPackages = with pkgs; [
    sops
    age
    ssh-to-age
  ];
}