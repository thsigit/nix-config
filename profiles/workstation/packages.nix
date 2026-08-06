# profiles/workstation/packages.nix

{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    deskflow
    google-chrome
    cudatext
  ];
}
