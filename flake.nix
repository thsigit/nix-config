# flake.nix

{
  description = "Homelab NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, sops-nix, ... }:

    let
      system = "x86_64-linux";

      commonSpecialArgs = { };

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
      server =
        mkSystem "portege-r30c" "server";

      workstation =
        mkSystem "portege-r30c" "workstation";

      failsafe =
        mkSystem "portege-r30c" "failsafe";
    };
  };
}
