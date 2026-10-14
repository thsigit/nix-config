# common/web/nix-journal.nix
#
# Zensical static site generator for the codebot technical reports (the
# journal). Source content lives in /srv/repo/nix-journal (git repo,
# publishable to GitHub Pages). Clean layout, matching blog/article/academic:
# the site is built into the repo-local site/ dir, then rsynced to the public
# dir /srv/www/nix-journal. Served locally at homelab.home.arpa/journal and
# published to GitHub Pages (project site at /nix-journal/).
#
# Migration note (2026-10-14): the public dir was /srv/www/codebot, a two-way
# symlink shim -- docs/, overrides/, scripts/ and zensical.toml pointed from
# the public dir back into the repo, and the repo's journal/ pointed out to
# the public dir. That shim is gone; there are no symlinks now. The route is
# still /journal so existing links and site_url stay valid.
{ config, pkgs, ... }:
let
  defaults = import ../../settings;
  inherit (defaults) domain directories;
  inherit (defaults) user;
  repoDir = "/srv/repo/nix-journal";
  stageDir = "${repoDir}/build_docs";
  siteDir = "${repoDir}/site";
  publicDir = "${directories.www}/nix-journal";
in
{
  environment.systemPackages = [ pkgs.zensical pkgs.rsync ];

  systemd.tmpfiles.rules = [
    "d ${publicDir} 0755 ${user.name} ${user.group} -"
  ];

  systemd.services.zensical-build-journal = {
    description = "Build Zensical site (nix journal)";
    serviceConfig = {
      Type = "oneshot";
      User = user.name;
      WorkingDirectory = repoDir;
    };
    # Stage docs through gen_home.py, which regenerates the index and runs the
    # navigation validator (missing nav.part, non-contiguous parts, one-way
    # prev/next, empty titles, self-references, dead slugs are build errors).
    # The stage lives at ${repoDir}/build_docs, NOT under docs/, so writing the
    # index does not retrigger zensical-build-journal.path.
    script = ''
      set -euo pipefail
      ${pkgs.python3}/bin/python3 scripts/gen_home.py --stage ${stageDir}
      conf="$(mktemp "$PWD/zensical.build.XXXX.toml")"
      trap 'rm -f "$conf"' EXIT
      ${pkgs.gnused}/bin/sed -e "s#^docs_dir = .*#docs_dir = \"build_docs\"#" zensical.toml > "$conf"
      ${pkgs.zensical}/bin/zensical build -f "$conf"
      ${pkgs.rsync}/bin/rsync -a --delete ${siteDir}/ ${publicDir}/
    '';
  };

  systemd.paths.zensical-build-journal = {
    description = "Watch nix-journal docs for changes";
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      PathModified = "${repoDir}/docs";
    };
  };

  # Serve the journal under the homelab.home.arpa host at the /journal path.
  # tls is already declared on this vhost by other modules; extraConfig is
  # mergeable (types.lines), so we only add the route.
  services.caddy.virtualHosts."homelab.${domain}".extraConfig = ''
    handle_path /journal/* {
      root * ${publicDir}
      file_server
    }
    handle /journal {
      redir /journal/ 308
    }
  '';
}
