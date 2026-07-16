# modules/ai/litellm/default.nix

{ config, lib, pkgs, ... }:

{
  imports = [
    ./settings.nix
    ./router.nix
    ./postgres.nix
    (import ./models.nix { providers = import ./providers.nix; })
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

    # Disable cache to avoid prisma requirement
    environment = {
      LITELLM_DISABLE_CHAT_CACHE = "true";
    };

    # Provided by secrets.nix
    environmentFile = config.sops.secrets."litellm.env".path;
  };
}