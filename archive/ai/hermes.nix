# modules/ai/hermes.nix
{ hermes-agent, pkgs, ... }:

{
  environment.systemPackages = [
    hermes-agent.packages.${pkgs.system}.default
  ];
  
  # services.hermes-agent = {
  #   enable = true;
  #   settings.model.default = "anthropic/claude-sonnet-4"; 
  #   environmentFiles = [ config.sops.secrets."hermes-env".path ];
  #   port = 8080;
  # };
}