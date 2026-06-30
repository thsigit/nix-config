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

    mkSystem = machine: profile:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = commonSpecialArgs;

        modules = [
          (./machines + "/${machine}")
          (./profiles + "/${profile}")
        ];
      };
	  
  in {
    nixosConfigurations = {
      homelab =
        mkSystem "portege-r30c" "homelab";

      workstation =
        mkSystem "vantage-v14g4" "workstation";
    };
  };
}