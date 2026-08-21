# common/ai/litellm/litellm-cli.nix
#
# Local wiring for the independent `services.litellm-cli` module (imported
# from the litellm-cli repo). Self-enabling leaf: importing this file enables
# the config layer + admin CLI. The native runtime (./litellm.nix)
# consumes its rendered config via config.services.litellm-cli.configFile.
#
# Persistence contract:
#   dataDir (persistent) → providers.json (admin-owned, survives reinstall)
#   /run/litellm-cli     → models.json, config.yaml, health.json (rebuilt each boot)
{ config, lib, litellmCli, ... }:

let
  defaults = import ../../../settings;
  inherit (defaults.directories) appdata;
in
{
  imports = [ (litellmCli + "/module.nix") ];

  services.litellm-cli = {
    enable = true;
    # Persistent admin-owned data root. providers.json (the source of truth)
    # lives here and survives partition reformat/reinstall.
    dataDir = "${appdata}/litellm";
    # State files are owned by the regular user so `litellm-cli` works without sudo.
    user = defaults.user.name;
    group = defaults.user.group;
    providersEnvFile = config.sops.secrets."providers.env".path;
  };

  system.activationScripts.litellm-healthjson-prep = {
    deps = [ "users" ];
    text = ''
      mkdir -p /run/litellm-cli
      [ -e /run/litellm-cli/health.json ] || echo '{}' > /run/litellm-cli/health.json
    '';
  };

system.activationScripts.litellm-cli-config.deps = [ "users" "litellm-healthjson-prep" ];
}
