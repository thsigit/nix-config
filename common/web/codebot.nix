# common/web/codebot.nix
#
# Zensical static site generator for codebot reports.
# Source content lives in /srv/repo/nix-journal (git repo, publishable to
# GitHub Pages). /srv/www/codebot is a thin shim that retains the "codebot"
# author name: it symlinks back to the repo for inputs (docs, overrides,
# scripts, zensical.toml) and holds the generated output in journal/.
# Served at journal.home.arpa via Caddy.
{ config, pkgs, ... }:
let
  defaults = import ../../settings;
  inherit (defaults) domain;
  sslDir = "/etc/ssl/homelab";
  shimDir = "/srv/www/codebot";
  repoDir = "/srv/repo/nix-journal";
  journalDir = "${shimDir}/journal";
  configFile = "${shimDir}/zensical.toml";
in
{
  environment.systemPackages = [ pkgs.zensical ];

  # NOTE: docs/overrides/scripts/zensical.toml are symlinks into the repo, so we
  # use `L` (symlink) rules, never `d` (a `d` on a symlink would replace it with
  # an empty real directory). The output symlink (repo journal -> shim journal)
  # is also recreated here so zensical's realpath resolution lands in the shim.
  systemd.tmpfiles.rules = [
    "d ${shimDir} 0755 sigit users -"
    "L ${shimDir}/docs - - - - ${repoDir}/docs"
    "L ${shimDir}/overrides - - - - ${repoDir}/overrides"
    "L ${shimDir}/scripts - - - - ${repoDir}/scripts"
    "L ${shimDir}/zensical.toml - - - - ${repoDir}/zensical.toml"
    "L ${repoDir}/journal - - - - ${shimDir}/journal"
    "d ${journalDir} 0755 sigit users -"
  ];

  systemd.services.zensical-build = {
    description = "Build Zensical site (codebot journal)";
    serviceConfig = {
      Type = "oneshot";
      User = "sigit";
      WorkingDirectory = shimDir;
    };
    script = "${pkgs.zensical}/bin/zensical build -f ${configFile}";
  };

  systemd.paths.zensical-build = {
    description = "Watch codebot docs for changes";
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      # Watch the real repo docs dir (a symlink's own inode never changes, so
      # watching the shim symlink would not trigger rebuilds on source edits).
      PathModified = "${repoDir}/docs";
    };
  };

  services.caddy.virtualHosts."journal.${domain}" = {
    extraConfig = ''
      tls ${sslDir}/homelab.crt ${sslDir}/homelab.key
      root * ${journalDir}
      file_server
      encode gzip zstd
    '';
  };
}
