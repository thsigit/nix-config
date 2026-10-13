# common/web/blog.nix
#
# Zensical static site for sigit's personal blog.
# Clean layout (no symlinks, unlike codebot.nix): source lives in
# /srv/repo/blog, is built into the repo-local site/ dir, then rsynced to the
# public dir /srv/www/blog. Served locally at homelab.home.arpa/blog.
{ config, pkgs, ... }:
let
  defaults = import ../../settings;
  inherit (defaults) domain directories;
  inherit (defaults) user;
  repoDir = "/srv/repo/blog";
  siteDir = "${repoDir}/site";
  publicDir = "${directories.www}/blog";
in
{
  environment.systemPackages = [ pkgs.zensical pkgs.rsync ];

  systemd.tmpfiles.rules = [
    "d ${publicDir} 0755 ${user.name} ${user.group} -"
  ];

  systemd.services.zensical-build-blog = {
    description = "Build Zensical site (sigit blog)";
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

  systemd.paths.zensical-build-blog = {
    description = "Watch blog docs for changes";
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      PathModified = "${repoDir}/docs";
    };
  };

  # Serve the blog under the homelab.home.arpa host at the /blog path.
  # tls is already declared on this vhost by other modules; extraConfig is
  # mergeable (types.lines), so we only add the route.
  services.caddy.virtualHosts."homelab.${domain}".extraConfig = ''
    handle_path /blog/* {
      root * ${publicDir}
      file_server
    }
    handle /blog {
      redir /blog/ 308
    }
  '';
}
