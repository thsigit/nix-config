# common/ai/litellm/default.nix
#
# LiteLLM gateway stack. This leaf imports the runtime + config + restart-helper
# modules. Database provisioning lives in common/db (original, untouched) and
# writes ${appdata}/litellm-podman/database.env, which litellm-podman.nix reads.
{ ... }:
{
  imports = [
    ./litellm-cli.nix
    ./litellm-podman.nix
    ./litellm-podman-helper.nix
  ];
}
