# common/ai/litellm/default.nix
#
# LiteLLM gateway stack. This leaf imports the config layer (litellm-cli)
# and the native runtime (litellm). Database provisioning lives in
# common/db and writes ${appdata}/litellm/database.env, which
# litellm.nix reads as an environmentFile.
{ ... }:
{
  imports = [
    ./litellm-cli.nix
    ./litellm.nix
  ];
}
