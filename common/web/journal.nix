# common/web/journal.nix
#
# Zola static site generator for the journal.
# Markdown in /srv/www/codebot/docs is transformed into Zola content by
# /srv/www/journal/sync.sh (bold-metadata -> TOML frontmatter), then built
# into /srv/www/journal/public by a oneshot systemd service, triggered
# automatically by a path unit whenever the docs tree changes.
# Served at journal.home.arpa via Caddy.
{ config, pkgs, ... }:
let
  defaults = import ../../settings;
  inherit (defaults) domain;
  sslDir = "/etc/ssl/homelab";
  docsDir = "/srv/www/codebot/docs";
  journalDir = "/srv/www/journal";
  publicDir = "${journalDir}/public";
in
{
  environment.systemPackages = [ pkgs.zola ];

  systemd.tmpfiles.rules = [
    "d ${journalDir} 0755 sigit users -"
    "d ${journalDir}/content/posts 0755 sigit users -"
    "d ${publicDir} 0755 sigit users -"
  ];

  systemd.services.journal-build = {
    description = "Build Zola journal site from codebot docs";
    serviceConfig = {
      Type = "oneshot";
      User = "sigit";
      WorkingDirectory = journalDir;
    };
    script = ''
      ${pkgs.bash}/bin/bash ${journalDir}/sync.sh
      ${pkgs.zola}/bin/zola build
    '';
  };

  systemd.paths.journal-build = {
    description = "Watch codebot docs for journal rebuilds";
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      PathModified = docsDir;
    };
  };

  services.caddy.virtualHosts."journal.${domain}" = {
    extraConfig = ''
      tls ${sslDir}/homelab.crt ${sslDir}/homelab.key
      root * ${publicDir}
      file_server
      encode gzip zstd
    '';
  };
}
