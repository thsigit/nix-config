# common/web/codebot.nix
#
# Zensical static site generator for codebot reports.
# Markdown in /srv/www/codebot/docs is built into /srv/www/codebot/reports
# by a oneshot systemd service, triggered automatically by a path unit
# whenever the docs tree changes. Served at reports.home.arpa via Caddy.
{ config, pkgs, ... }:
let
  defaults = import ../../settings;
  inherit (defaults) domain;
  sslDir = "/etc/ssl/homelab";
  codebotDir = "/srv/www/codebot";
  docsDir = "${codebotDir}/docs";
  reportsDir = "${codebotDir}/reports";
  configFile = "${codebotDir}/zensical.toml";
in
{
  environment.systemPackages = [ pkgs.zensical ];

  systemd.tmpfiles.rules = [
    "d ${docsDir} 0755 sigit users -"
    "d ${reportsDir} 0755 sigit users -"
  ];

  systemd.services.zensical-build = {
    description = "Build Zensical site (codebot reports)";
    serviceConfig = {
      Type = "oneshot";
      User = "sigit";
      WorkingDirectory = codebotDir;
    };
    script = "${pkgs.zensical}/bin/zensical build -f ${configFile}";
  };

  systemd.paths.zensical-build = {
    description = "Watch codebot docs for changes";
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      PathModified = docsDir;
    };
  };

  services.caddy.virtualHosts."reports.${domain}" = {
    extraConfig = ''
      tls ${sslDir}/homelab.crt ${sslDir}/homelab.key
      root * ${reportsDir}
      file_server
      encode gzip zstd
    '';
  };
}
