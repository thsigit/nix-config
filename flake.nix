# flake.nix

{
  description = "Homelab NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    hermes-agent.url = "github:NousResearch/hermes-agent";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, hermes-agent, sops-nix, ... }:
  
    let
      system = "x86_64-linux";
    
      commonSpecialArgs = {
        inherit hermes-agent;
      };
    
      mkSystem = machine: profile:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = commonSpecialArgs;
    
          modules = [
            sops-nix.nixosModules.sops
            (./machines + "/${machine}")
            (./profiles + "/${profile}")
          ];
        };	  
    in {

    nixosConfigurations = {
      homelab =
        mkSystem "portege-r30c" "homelab";

      workstation =
        mkSystem "portege-r30c" "workstation";
    };
  };
}