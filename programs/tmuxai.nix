# programs/tmuxai.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    tmuxai apache-answer
  ];
}
