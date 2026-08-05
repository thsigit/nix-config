# modules/ai/bitrouter/default.nix
# BitRouter — LLM gateway (OpenAI/Anthropic/Gemini-compatible router).
#
# Package, settings, and both run modes (native / container) share one
# config file and one binary. package.nix is a derivation (callPackage'd
# from settings.nix), not a module.
#
# Enabled here in container mode (the prototype gateway). To disable
# BitRouter entirely, comment out `./bitrouter` in modules/ai/default.nix.
# To run native instead of container, set mode = "native" here.

{ config, lib, ... }:

{
  imports = [
    ./settings.nix
    ./service.nix
    ./container.nix
  ];

  services.bitrouter.enable = true;
  services.bitrouter.mode = "container";
  # Provider keys (zero-config auto-detection: OPENROUTER/GEMINI/... from providers.env).
  services.bitrouter.environmentFiles = [ config.sops.secrets."providers.env".path ];
}
