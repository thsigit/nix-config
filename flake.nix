{
  description = "Homelab NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    hermes-agent.url = "github:NousResearch/hermes-agent";
  };

  outputs = { self, nixpkgs, hermes-agent, ... }:
  let
    system = "x86_64-linux";
  in {
    nixosConfigurations.homelab = nixpkgs.lib.nixosSystem {
      inherit system;

      modules = [
        hermes-agent.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}