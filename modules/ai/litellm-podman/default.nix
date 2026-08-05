# modules/ai/litellm-podman/default.nix
# LiteLLM gateway (Podman container) — runtime + config layer.
#
# Enables both pieces of the LiteLLM Podman gateway:
#   - podman.nix   — the gateway container (upstream image, port 4000)
#   - config.nix   — inventory/policy wrapper + config.yaml renderer
#
# To disable LiteLLM entirely, comment out `./litellm-podman` in
# modules/ai/default.nix. To keep the runtime but drop the wrapper
# tooling, set ai.litellmConfig.enable = false here.

{ lib, ... }:

{
  imports = [
    ./podman.nix
    ./config.nix
  ];

  ai.podmanLitellm.enable = true;
  ai.litellmConfig.enable = true;
}
