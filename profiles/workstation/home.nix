# profiles/workstation/home.nix
# Home-manager user config for sigit.
{ config, lib, pkgs, ... }:

{
  home = {
    username = "sigit";
    homeDirectory = "/home/sigit";
    stateVersion = "26.05";
  };

  programs.home-manager.enable = true;

  programs.bash = {
    enable = true;
    enableCompletion = true;
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "Sigit Prasetyo";
      user.email = "sigit.prasetyo@home.arpa";
    };
  };
}
