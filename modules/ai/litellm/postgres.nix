# modules/ai/litellm/postgres.nix
# PostgreSQL for LiteLLM
#
# Gated by config.litellm.enable (default false) — runtime moved to podman-litellm.

{ config, lib, ... }:

lib.mkIf config.litellm.enable {
  services.postgresql = {
    enable = true;

    ensureDatabases = [ "litellm" ];

    ensureUsers = [
      {
        name = "litellm";
        ensureDBOwnership = true;
      }
    ];
  };
}
