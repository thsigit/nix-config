# services/ai/default.nix
{ ... }:
{
  imports = [
    ./llama-cpp.nix
    ./vane.nix
    ./opencode.nix
    ./bitrouter.nix
    ./litellm.nix
  ];
}
