# common/security/sops.nix

{ config, pkgs, ... }:
let
  defaults = import ../../settings;
  inherit (defaults) user;
in

{
  sops = {
    age.keyFile = "/home/${user.name}/.config/sops/age/keys.txt";
  };

  sops.secrets."providers.env" = {
    sopsFile = ../../secrets/providers.env;
    format = "dotenv";
    owner = user.name;
    group = user.group;
    mode = "0440";
  };

  # Access-point stack secrets (hostapd/FreeRADIUS) — encrypted in
  # secrets/ and decrypted at activation into /run/secrets.
  sops.secrets."radius-secret" = {
    sopsFile = ../../secrets/radius.yaml;
    format = "yaml";
  };

  sops.secrets."radius-users" = {
    sopsFile = ../../secrets/radius.yaml;
    format = "yaml";
  };

  environment.systemPackages = with pkgs; [
    sops
    age
    ssh-to-age
  ];
}
