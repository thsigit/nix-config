# programs/sqlite.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    sqlite alejandra
  ];
}
