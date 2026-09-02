# common/ai/litellm/litellm-cli.nix
#
# Local wiring for the independent `services.litellm-cli` module (imported
# from the litellm-cli repo). Self-enabling leaf: importing this file enables
# the admin CLI + config editor layer.
#
# Static config contract:
#   The LiteLLM config.yaml is a STATIC, hand-maintained file living at
#   common/ai/litellm/config.yaml and copied to ${config.services.litellm-cli.configFile}
#   at activation by the native runtime module (./litellm.nix). litellm-cli
#   only EDITS that static file manually; it never renders or seeds anything.
#
# Persistence contract:
#   dataDir (persistent) → usage_logger.py (callback module), survives reinstall
#   /run/litellm-cli     → health.json (ephemeral, rebuilt each boot)
{ config, lib, litellmCli, ... }:

let
  defaults = import ../../../settings;
  inherit (defaults.directories) appdata;
in
{
  imports = [ (litellmCli + "/module.nix") ];

  services.litellm-cli = {
    enable = true;
    # runs as the regular user so `litellm-cli` works without sudo
    dataDir = "${appdata}/litellm";
    user = defaults.user.name;
    group = defaults.user.group;
    providersEnvFile = config.sops.secrets."providers.env".path;
  };
}
