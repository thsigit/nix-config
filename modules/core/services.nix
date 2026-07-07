# modules/core/services.nix

{ config, lib, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  programs.ydotool.enable = true;

  programs.bash = {
    promptInit = ''
    export PS1="\[\e[1;36m\]🏠 HOMELAB \[\e[0m\]\w (\u) $ "
    '';
    completion = {
      enable = true;
      package = pkgs.bash-completion;
    };
    
  };


  programs.tmux = {
    enable = true;
    aggressiveResize = true;
    historyLimit = 10000;
    clock24 = true;
    extraConfig = ''
      set -g @continuum-restore 'on'
      set -g @continuum-save-interval '60'

      set -g @resurrect-capture-pane-contents 'on'
      set -g @resurrect-processes 'ssh'

      set -g @thumbs-key 't'
      set -g @thumbs-unique 'enabled'
      set -g @tmux_power_theme 'gold'
      set -g default-terminal "screen-256color"
      set -as terminal-features ",xterm-256color:RGB"
    '';
    newSession = true;
    plugins = with pkgs.tmuxPlugins; [
      resurrect
      continuum
      tmux-fzf
      extrakto
      session-wizard
      yank
      tmux-thumbs
      cpu
      power-theme
      sensible
    ];
  };

  powerManagement.cpuFreqGovernor = "performance";
}