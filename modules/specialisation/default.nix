# modules/specialisation/default.nix

{ config, lib, pkgs, ... }:

{
  specialisation = {

    sway.configuration = {
      imports = [
        ./sway.nix
      ];
    };

    #labs.configuration = {
    #  inheritParentConfig = false;
    #  imports = [
    #    ./labs.nix
    #  ];
    #};

  };
}