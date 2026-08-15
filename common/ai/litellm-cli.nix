# common/ai/litellm-cli.nix
#
# Local wiring for the independent `services.litellm-cli` module (imported
# from the litellm-cli repo). Self-enabling leaf: importing this file enables
# the config layer + admin CLI. The Podman runtime (./litellm-podman.nix)
# consumes its rendered config via config.services.litellm-cli.configFile.
{ config, litellmCli, ... }:

let
  defaults = import ../../settings;
  inherit (defaults.directories) appdata;
in
{
  imports = [ (litellmCli + "/module.nix") ];

  services.litellm-cli = {
    enable = true;
    # Admin-configurable gateway.json / models.json / config.yaml / health.json
    # live here; the podman runtime keeps its own data under litellm-podman.
    stateDir = "${appdata}/litellm-cli";
    # State files are owned by the regular user so `litellm-cli` works without sudo.
    user = defaults.user.name;
    group = defaults.user.group;
    providersEnvFile = config.sops.secrets."providers.env".path;
  };
}
