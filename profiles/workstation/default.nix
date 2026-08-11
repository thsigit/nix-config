# profiles/workstation/default.nix
{ config, lib, pkgs, callPackage, home-manager, ... }:
{
  imports = [
    ../../system
    ../../modules
    home-manager.nixosModules.home-manager
    ./xfce4.nix
    ./packages.nix
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.sigit = import ./home.nix;
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "google-chrome"
  ];
}
