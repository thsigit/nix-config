# modules/ai/litellm/router.nix
# LiteLLM router settings
#
# Gated by config.litellm.enable (default false) — runtime moved to podman-litellm.

{ config, lib, ... }:

lib.mkIf config.litellm.enable {
  services.litellm.settings.router_settings = {
    # ...
  };
}
