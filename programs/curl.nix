# programs/curl.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    curl wget
  ];
}
