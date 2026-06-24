# modules/ai/hermes.nix

{ config, pkgs, ... }:

let
  hermes-flake = builtins.getFlake "github:NousResearch/hermes-agent";
in
{
  imports = [
    hermes-flake.nixosModules.default
  ];

  services.hermes-agent = {
    enable = true;
    # settings.model.default = "anthropic/claude-sonnet-4"; 
    # environmentFiles = [ config.sops.secrets."hermes-env".path ];
    addToSystemPackages = true; # 
  };
}