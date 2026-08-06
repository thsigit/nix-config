# programs/jq.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    jq yq
  ];
}
