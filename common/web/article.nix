# common/web/article.nix
#
# Zensical static site for the article channel (objective, popular writing:
# explainers, news, factual analysis).
# Clean layout: source lives in /srv/repo/article, is built into the repo-local
# site/ dir, then rsynced to the public dir /srv/www/article. Served locally at
# homelab.home.arpa/article.
{ config, pkgs, ... }:
let
  defaults = import ../../settings;
  inherit (defaults) domain directories;
  inherit (defaults) user;
  repoDir = "/srv/repo/article";
  siteDir = "${repoDir}/site";
  publicDir = "${directories.www}/article";
in
{
  environment.systemPackages = [ pkgs.zensical pkgs.rsync ];

  systemd.tmpfiles.rules = [
    "d ${publicDir} 0755 ${user.name} ${user.group} -"
  ];

  systemd.services.zensical-build-article = {
    description = "Build Zensical site (article)";
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

  systemd.paths.zensical-build-article = {
    description = "Watch article docs for changes";
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      PathModified = "${repoDir}/docs";
    };
  };

  # Serve the article channel under homelab.home.arpa at the /article path.
  services.caddy.virtualHosts."homelab.${domain}".extraConfig = ''
    handle_path /article/* {
      root * ${publicDir}
      file_server
    }
    handle /article {
      redir /article/ 308
    }
  '';
}
