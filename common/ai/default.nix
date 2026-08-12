# common/ai/default.nix
#
# Wires the AI gateway concerns. The LiteLLM config layer + admin CLI live in
# the independent `services.litellm-cli` module (imported from the litellm-cli
# repo). The Podman runtime (ai.podmanLitellm) is a separate, decoupled module
# that only consumes the rendered config.yaml. Either can be toggled independently.
{ config, litellmCli, ... }:

let
  defaults = import ../../settings;
  inherit (defaults.directories) appdata;
in
{
  imports = [
    ./llama-cpp.nix
    ./vane-container.nix
    ./opencode.nix
    ./bitrouter.nix
    ./litellm-podman.nix
    # Independent, releasable module: config layer + admin CLI.
    (litellmCli + "/module.nix")
  ];

  services.bitrouter = {
    enable = true;
    environmentFiles = [ config.sops.secrets."providers.env".path ];
  };

  services.litellm-cli = {
    enable = true;
    # Keep runtime state alongside the container's appdata for a single tree.
    stateDir = "${appdata}/litellm-container";
    providersEnvFile = config.sops.secrets."providers.env".path;
  };

  ai.podmanLitellm.enable = true;
}
