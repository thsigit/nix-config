# modules/packages/bash.nix
{ config, lib, pkgs, ... }:
{
  programs.bash = {
    promptInit = ''
      export PS1="\[\e[1;36m\]🏠 HOMELAB \[\e[0m\]\w (\u) \$ "
    '';
    completion = {
      enable = true;
      package = pkgs.bash-completion;
    };
  };

  powerManagement.cpuFreqGovernor = "performance";
}
