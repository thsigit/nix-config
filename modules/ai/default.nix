# modules/ai/default.nix
{ ... }:
{
  imports = [
    ./llama-cpp.nix
    ./vane-container.nix
    ./opencode.nix
    ./bitrouter.nix
    ./litellm.nix
    # ./litellm-container.nix  # container variant (disabled reference)
  ];
}
