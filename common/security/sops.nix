# system/sops.nix

{ config, pkgs, ... }:

{
  sops = {
    age.keyFile = "/home/sigit/.config/sops/age/keys.txt";
  };

  sops.secrets."providers.env" = {
    sopsFile = ../../secrets/providers.env;
    format = "dotenv";
    owner = "sigit";
    group = "users";
    mode = "0440";
  };

  # Access-point stack secrets (hostapd/FreeRADIUS/openNDS) — encrypted in
  # secrets/ and decrypted at activation into /run/secrets.
  sops.secrets."radius-secret" = {
    sopsFile = ../../secrets/radius.yaml;
    format = "yaml";
  };

  sops.secrets."radius-users" = {
    sopsFile = ../../secrets/radius.yaml;
    format = "yaml";
  };

  sops.secrets."opennds-faskey" = {
    sopsFile = ../../secrets/opennds.yaml;
    format = "yaml";
  };

  environment.systemPackages = with pkgs; [
    sops
    age
    ssh-to-age
  ];
}
