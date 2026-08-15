# common/ai/default.nix
#
# AI gateway stack. Each leaf module owns its own defaults and is always-on
# when imported (mrtg-style standard) — this file is a pure index.
# The LiteLLM config layer + admin CLI (`services.litellm-cli`) are wired in
# ./litellm-cli.nix, which imports that module from the litellm-cli repo.
{ config, lib, litellmCli, ... }:
{
  imports = [
    ./llama-cpp.nix
    ./vane-podman.nix
    ./opencode.nix
    ./bitrouter.nix
    ./litellm-cli.nix
    ./litellm-podman.nix
    ./litellm-podman-helper.nix
  ];

  options.ai.litellmPodman.configFile = lib.mkOption {
    type = lib.types.str;
    description = "Path to the rendered LiteLLM config.yaml consumed by the Podman runtime and watched by the restart helper.";
  };

  config.ai.litellmPodman.configFile = config.services.litellm-cli.configFile;
}
