{
  description = "Homelab NixOS flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    hermes-agent.url = "github:NousResearch/hermes-agent";
  };
  outputs = { self, nixpkgs, hermes-agent, ... }:
  let
    system = "x86_64-linux";
    commonSpecialArgs = {
      inherit hermes-agent;
    };
  in { 
    nixosConfigurations = {
      homelab = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = commonSpecialArgs;
        modules = [ ./hosts/homelab ];
      };
      workspace = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = commonSpecialArgs;
        modules = [ ./hosts/workspace ];
      };
    };
  };
}