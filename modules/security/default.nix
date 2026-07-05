# modules/security/default.nix 

{ config, lib, pkgs, ... }:

{  
  imports = [
    ./insecure-packages.nix
    ./pki.nix
    ./ssh.nix
    ./firewall.nix
    ./sops.nix
  ];

#  sops.defaultSopsFile = ../secrets/common.yaml;
#  sops.defaultSopsFormat = "yaml";

#  sops.age.keyFile = "/home/sigit/.config/sops/age/keys.txt";

#  sops.secrets.litellm-env = {
#    key = "litellm.env";
#    owner = "litellm";
#    group = "litellm";
#    mode = "0400";
#  };  
}