# modules/ai/litellm/default.nix
# Composition entry point — imports all layers of the AI gateway controller

{ config, lib, pkgs, ... }:

{
  imports = [
    ./state.nix
    ./settings.nix
    ./router.nix
    ./postgres.nix
    ./models.nix
    ./renderer.nix
    ./health.nix
    ./cli.nix
    ./fetch-models-service.nix
  ];

  services.caddy.services.litellm.port = 4000;

  services.litellm = {
    enable = true;
    package = pkgs.litellm;
    host = "127.0.0.1";
    port = 4000;

    openFirewall = false;

    environmentFile = config.sops.secrets."litellm.env".path;

    environment = {
      LITELLM_DISABLE_CHAT_CACHE = "true";
    };

    health.enable = true;

    settings = {
      general_settings = {
        master_key = "os.environ/LITELLM_MASTER_KEY";
      };
      litellm_settings = {
        json_logs = true;
        drop_params = true;
      };
    };
  };
}
