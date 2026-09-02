# common/ai/default.nix
#
# AI gateway stack. Each leaf module owns its own defaults and is always-on
# when imported (mrtg-style standard) — this file is a pure index.
{ ... }:
{
  imports = [
    ./llama-cpp.nix
    ./opencode.nix
    ./litellm
  ];
}
