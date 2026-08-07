# modules/ai/default.nix
{ ... }:
{
  imports = [
    ./llama-cpp.nix
    ./vane-container.nix
    ./opencode.nix
    ./bitrouter.nix
    ./litellm-container.nix
  ];

  ai.podmanLitellm.enable = true;
  ai.litellmConfig.enable = true;
}
