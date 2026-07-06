# profiles/workstation/packages.nix

{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    deskflow
    microsoft-edge
    koboldcpp
    cudatext
    plano-theme
    numix-icon-theme
    vimix-icon-theme
  ];
}
