# profiles/workstation/home.nix
# Home-manager user config for sigit.
{ config, lib, pkgs, ... }:

let
  # Dotfiles working tree (out-of-store symlinks: live edits survive rebuilds;
  # GUI/xfconfd changes land in the repo, commit them from /srv/repo/dotfiles).
  dotfiles = "/srv/repo/dotfiles";
in
{
  home = {
    username = "sigit";
    homeDirectory = "/home/sigit";
    stateVersion = "26.05";
    sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];
  };

  programs.home-manager.enable = true;

  programs.bash = {
    enable = true;
    enableCompletion = true;
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "thsigit";
      user.email = "th.sigit@gmail.com";
    };
  };

  # Dotfiles-managed config (out-of-store symlinks into /srv/repo/dotfiles).
  # xfce4: whole dir (xfconfd writes through the symlink into the repo).
  home.file = {
    ".config/xfce4".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/xfce4";
    ".config/gh/config.yml" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/gh/config.yml";
      force = true;
    };
    ".config/autostart".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/autostart";
    ".config/mimeapps.list" = {
      source = ./mimeapps.list;
      force = true;
    };
  };

  # XFCE desktop settings (wallpaper, backdrop style) are owned by the
  # dotfiles repo via the .config/xfce4 symlink - no xfconf.settings here,
  # so rebuilds never revert GUI changes.
}
