# common/ai/litellm-cli.nix
#
# Local wiring for the independent `services.litellm-cli` module (imported
# from the litellm-cli repo). Self-enabling leaf: importing this file enables
# the config layer + admin CLI. The Podman runtime (./litellm-podman.nix)
# consumes its rendered config via config.services.litellm-cli.configFile.
#
# Persistence contract:
#   dataDir (persistent) → gateway.json (admin-owned, survives reinstall)
#   /run/litellm        → models.json, config.yaml, health.json (rebuilt each boot)
{ config, litellmCli, ... }:

let
  defaults = import ../../settings;
  inherit (defaults.directories) appdata;
in
{
  imports = [ (litellmCli + "/module.nix") ];

  services.litellm-cli = {
    enable = true;
    # Persistent admin-owned data root. gateway.json (the source of truth)
    # lives here and survives partition reformat/reinstall.
    dataDir = "${appdata}/litellm";
    # State files are owned by the regular user so `litellm-cli` works without sudo.
    user = defaults.user.name;
    group = defaults.user.group;
    providersEnvFile = config.sops.secrets."providers.env".path;
  };
}
