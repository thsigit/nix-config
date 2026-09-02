# common/web/codebot.nix
#
# Zensical static site generator for codebot reports.
# Source content lives in /srv/repo/nix-journal (git repo, publishable to
# GitHub Pages). /srv/www/codebot is a thin shim that retains the "codebot"
# author name: it symlinks back to the repo for inputs (docs, overrides,
# scripts, zensical.toml) and holds the generated output in journal/.
# Served locally at homelab.home.arpa/journal and published to GitHub Pages
# (project site at /nix-journal/).
{ config, pkgs, ... }:
let
  defaults = import ../../settings;
  inherit (defaults) domain;
  inherit (defaults) user;
  sslDir = defaults.security.sslDir;
  shimDir = "/srv/www/codebot";
  repoDir = "/srv/repo/nix-journal";
  journalDir = "${shimDir}/journal";
  configFile = "${shimDir}/zensical.toml";
in
{
  environment.systemPackages = [ pkgs.zensical ];

  systemd.tmpfiles.rules = [
    "d ${shimDir} 0755 ${user.name} ${user.group} -"
    "L ${shimDir}/docs - - - - ${repoDir}/docs"
    "L ${shimDir}/overrides - - - - ${repoDir}/overrides"
    "L ${shimDir}/scripts - - - - ${repoDir}/scripts"
    "L ${shimDir}/zensical.toml - - - - ${repoDir}/zensical.toml"
    "L ${repoDir}/journal - - - - ${shimDir}/journal"
    "d ${journalDir} 0755 ${user.name} ${user.group} -"
  ];

  systemd.services.zensical-build = {
    description = "Build Zensical site (codebot journal)";
    serviceConfig = {
      Type = "oneshot";
      User = user.name;
      WorkingDirectory = shimDir;
    };
    script = "${pkgs.zensical}/bin/zensical build -f ${configFile}";
  };

  systemd.paths.zensical-build = {
    description = "Watch codebot docs for changes";
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      PathModified = "${repoDir}/docs";
    };
  };

  # Serve the journal under the homelab.home.arpa host at the /journal path.
  services.caddy.virtualHosts."homelab.${domain}" = {
    extraConfig = ''
      tls ${sslDir}/homelab.crt ${sslDir}/homelab.key
      handle_path /journal/* {
        root * ${journalDir}
        file_server
      }
      handle /journal {
        redir /journal/ 308
      }
    '';
  };
}
