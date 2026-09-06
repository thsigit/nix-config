# flake.nix

{
  description = "Homelab NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    litellm-cli = {
      url = "path:/srv/repo/litellm-cli";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, sops-nix, home-manager, ... }:

    let
      system = "x86_64-linux";

      commonSpecialArgs = {
        litellmCli = self.inputs.litellm-cli;
        inherit home-manager;
      };

      mkSystem = machine: profile:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = commonSpecialArgs;

          modules = [
            {
              nixpkgs.overlays = [
                (final: prev: {
                  llama-cpp = prev.llama-cpp.overrideAttrs (old: {
                    version = "10809";
                    src = final.fetchFromGitHub {
                      owner = "ggml-org";
                      repo = "llama.cpp";
                      rev = "v0.4.0";
                      hash = "sha256-WImZjO3U9EXZUNP/FMpxo8PaTjQW8X2SBTfGwwFlZIM=";
                    };
                    npmDepsHash = "sha256-2Q7XhaLAArmviOLdQsNbYTfdyDE5pW9lR26cRHEVl9k=";
                  });
                })
              ];
            }
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

      system =
        mkSystem "portege-r30c" "system";
    };
  };
}
