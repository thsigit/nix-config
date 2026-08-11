# common/ai/default.nix
{ config, ... }:
{
  imports = [
    ./llama-cpp.nix
    ./vane-container.nix
    ./opencode.nix
    ./bitrouter.nix
    ./litellm-container.nix
  ];

  services.bitrouter = {
    enable = true;
    environmentFiles = [ config.sops.secrets."providers.env".path ];
  };
  ai.podmanLitellm.enable = true;
  ai.litellmConfig.enable = true;
}
