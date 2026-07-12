# modules/ai/litellm/default.nix

{ config, lib, pkgs, ... }:

{
  imports = [
    ./settings.nix
    ./models.nix
    ./router.nix
    ./secrets.nix
    ./postgres.nix
  ];

  services.litellm = {
    enable = true;

    host = "127.0.0.1";
    port = 4000;

    # Caddy will proxy requests.
    openFirewall = false;

    # Provided by secrets.nix
    environmentFile = config.sops.secrets."litellm.env".path;
  };
}