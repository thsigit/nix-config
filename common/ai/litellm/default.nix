# common/ai/litellm/default.nix
#
# LiteLLM gateway stack. This leaf imports the config layer (litellm-cli)
# and the native runtime (litellm). Runs in no-DB mode — no PostgreSQL,
# no spend tracking, pure API proxying.
{ ... }:
{
  imports = [
    ./litellm-cli.nix
    ./litellm.nix
  ];
}
