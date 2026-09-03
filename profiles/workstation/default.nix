# profiles/workstation/default.nix
{ config, lib, pkgs, callPackage, home-manager, ... }:
let
  defaults = import ../../settings;
  inherit (defaults) user;
in
{
  imports = [
    ../../system
    ../../common
    home-manager.nixosModules.home-manager
    ./xfce4.nix
    ./packages.nix
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${user.name} = import ./home.nix;
  };

  services.ap.enable = true;
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "google-chrome"
  ];
}
