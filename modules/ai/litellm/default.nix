# modules/ai/litellm/default.nix

{ config, lib, pkgs, ... }:

{
  imports = [
    ./settings.nix
    ./router.nix
    ./postgres.nix
    ./models.nix
    ./fetch-models-service.nix
  ];

  services.caddy.services.litellm = {
    port = 4000;
  };

  services.litellm = {
    enable = true;
    package = pkgs.litellm;
    host = "127.0.0.1";
    port = 4000;

    # Caddy will proxy requests.
    openFirewall = false;

    environment = {
      LITELLM_DISABLE_CHAT_CACHE = "true";
    };

    # Provided by secrets.nix
    environmentFile = config.sops.secrets."litellm.env".path;
  };
}