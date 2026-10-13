# common/web/academic.nix
#
# Zensical static site for the academic channel (objective, scholarly writing:
# papers, reviews, theses, preprints).
# Clean layout: source lives in /srv/repo/academic, is built into the repo-local
# site/ dir, then rsynced to the public dir /srv/www/academic. Served locally at
# homelab.home.arpa/academic.
{ config, pkgs, ... }:
let
  defaults = import ../../settings;
  inherit (defaults) domain directories;
  inherit (defaults) user;
  repoDir = "/srv/repo/academic";
  siteDir = "${repoDir}/site";
  publicDir = "${directories.www}/academic";
in
{
  environment.systemPackages = [ pkgs.zensical pkgs.rsync ];

  systemd.tmpfiles.rules = [
    "d ${publicDir} 0755 ${user.name} ${user.group} -"
  ];

  systemd.services.zensical-build-academic = {
    description = "Build Zensical site (academic)";
    serviceConfig = {
      Type = "oneshot";
      User = user.name;
      WorkingDirectory = repoDir;
    };
    script = ''
      set -euo pipefail
      ${pkgs.zensical}/bin/zensical build -f zensical.toml
      ${pkgs.rsync}/bin/rsync -a --delete ${siteDir}/ ${publicDir}/
    '';
  };

  systemd.paths.zensical-build-academic = {
    description = "Watch academic docs for changes";
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      PathModified = "${repoDir}/docs";
    };
  };

  # Serve the academic channel under homelab.home.arpa at the /academic path.
  services.caddy.virtualHosts."homelab.${domain}".extraConfig = ''
    handle_path /academic/* {
      root * ${publicDir}
      file_server
    }
    handle /academic {
      redir /academic/ 308
    }
  '';
}
