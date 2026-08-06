# profiles/server/default.nix
{ config, lib, pkgs, ... }:
{
  imports = [
    ../../system
    #../../modules/ap
    ../../modules/packages
    ../../modules
  ];
}
