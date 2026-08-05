# modules/ai/litellm/default.nix
# AI gateway — just imports
#
# Disabled by default (2026-07-18): runtime moved to podman-litellm.
# Kept in tree as reference/codebase for the operational wrapper layer.

{ lib, ... }:

{
  options.litellm.enable = lib.mkEnableOption "LiteLLM AI gateway (systemd-native)";

  imports = [
    ./state.nix
    ./settings.nix
    ./router.nix
    ./postgres.nix
    ./gateway.nix
    ./activation.nix
    ./cli.nix
    ./maintenance.nix
    ./service.nix
  ];
}
