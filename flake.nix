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

    opencode = {
      url = "github:anomalyco/opencode";
    };
  };

  outputs = { self, nixpkgs, sops-nix, home-manager, opencode, ... }:

    let
      system = "x86_64-linux";

      commonSpecialArgs = {
        litellmCli = self.inputs.litellm-cli;
        inherit home-manager opencode;
      };

      mkSystem = machine: profile:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = commonSpecialArgs;

          modules = [
            {
              nixpkgs.config = {
                permittedInsecurePackages = [
                  "pnpm-9.15.9"
                ];
            
                allowUnfreePredicate = pkg:
                  builtins.elem (nixpkgs.lib.getName pkg) [
                    "google-chrome"
                    "open-webui"
                    "trilium-server"
                  ];
              };
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

      ai-gateway =
        mkSystem "portege-r30c" "ai-gateway";
    };
  };
}
