# common/ai/litellm/litellm.nix
#
# LiteLLM gateway runtime using the native services.litellm module.
#
# Static config architecture (no runtime render, no litellm-cli at build):
#
#   committed seed                    first activation                 runtime
#   ----------------                  ----------------                 -------
#   common/ai/litellm/config.yaml ->  copy if missing/empty       ->   litellm --config
#   (first boot default)               /srv/appdata/litellm/config.yaml /srv/appdata/litellm/config.yaml
#                                +   install usage_logger.py
#                                     -> /srv/appdata/litellm/
#
# The runtime config.yaml is ADMIN-EDITABLE and lives in /srv/appdata/litellm,
# the persistent replacement dir (survives /var deletion). It does NOT
# participate in nixos-rebuild: once seeded, rebuilds never overwrite it.
# The committed copy in this repo is only a first-boot default.
#
# Seed guard: the committed copy is installed when the live file is MISSING or
# ZERO-BYTE (empty config = litellm crash "Config cannot be None or Empty").
# An empty-but-present file used to dodge the seed (proof: 2026-09-12 outage).
#
# Ownership:
#   Nix owns: service definition + first-boot seed of the committed config.yaml
#   Repo owns: common/ai/litellm/config.yaml (model list, aliases, fallbacks)
#   Admin owns: /srv/appdata/litellm/config.yaml (the live, editable config)
#   SOPS owns: providers.env (API keys / master key)
#
# litellm-cli is a purely MANUAL tool that edits /srv/appdata/litellm/config.yaml.
# It is NOT invoked during nixos-rebuild or by any systemd unit.
#
# Frontend static files (index.html, litellm.js, admin.js, ui/playground/*)
# are deployed from the litellm-cli package on every rebuild to ensure
# reproducibility — no manual sync required.
#
{ config, lib, pkgs, ... }:

let
  litellmPort = 4000;
  stateDir = "/var/lib/litellm";
  # Committed first-boot seed.
  staticConfig = ./config.yaml;
  cliDataDir = config.services.litellm-cli.dataDir;
  # Effective runtime config: admin-editable, persistent, in the replacement dir.
  configFile = "${cliDataDir}/config.yaml";
in
{
  ##########################################################################
  # Assertions
  ##########################################################################

  assertions = [
    {
      assertion = config.services.litellm-cli.enable;
      message = ''
        services.litellm requires services.litellm-cli.enable = true.

        Import common/ai/litellm/litellm-cli.nix before enabling this module.
      '';
    }
  ];

  ##########################################################################
  # Caddy reverse proxy
  ##########################################################################

  services.caddy.services.ai = {
    port = litellmPort;
    preConfig = ''
      handle /api/* {
        reverse_proxy 127.0.0.1:8091
      }
      # Read-only LiteLLM endpoints: Caddy injects the master key so they are
      # callable WITHOUT a key on this private host (browser/curl navigation).
      # Admin/write endpoints remain key-gated (see :8091 above + :4000 below).
      @readonly path /health /health/liveness /health/readiness /health/services /v1/models /models /v1/model/info /model/info
      handle @readonly {
        reverse_proxy 127.0.0.1:4000 {
          header_up Authorization "Bearer {env.LITELLM_MASTER_KEY}"
        }
      }
      @frontend path / /litellm.js /ui/playground/* /stats.json
      handle @frontend {
        root * /srv/www/ai
        file_server
      }
      @litellmUI path /docs* /openapi.json /litellm-asset-prefix/* /swagger/*
      handle @litellmUI {
        respond "Not Found" 404
      }
    '';
  };

  ##########################################################################
  # Native LiteLLM service
  ##########################################################################

  services.litellm = {
    enable = true;
    port = litellmPort;
    host = "127.0.0.1";
    stateDir = stateDir;
    environmentFile = config.sops.secrets."providers.env".path;

    # All runtime settings (model_list, router_settings, litellm_settings,
    # general_settings) live in the admin-edited ${configFile}, seeded from the
    # committed config.yaml and never re-rendered. The upstream module's
    # `settings` generates an unused config.yaml because ExecStart is overridden
    # below to point at ${configFile}; keep this empty to avoid dead duplication
    # (single source of truth = config.yaml).
    settings = { };
  };

  ##########################################################################
  # Static config deployment (replaces litellm-cli render completely)
  ##########################################################################

  system.activationScripts.litellm-static-config = lib.stringAfter [ "users" ] ''
    set -euo pipefail
    mkdir -p ${cliDataDir}

    # Seed the admin-editable config.yaml from the committed copy on first
    # deployment, AND anytime the live copy is empty (zero bytes = broken
    # config; litellm aborts with "Config cannot be None or Empty"). Once
    # present as valid content it is edited by hand / litellm-cli and must
    # survive rebuilds untouched.
    if [ ! -f ${configFile} ] || [ ! -s ${configFile} ]; then
      install -m0644 ${staticConfig} ${configFile}
    fi

    # usage_logger callback: always (re)install from the package.
    install -m0644 ${config.services.litellm-cli.package}/data/usage_logger.py ${cliDataDir}/usage_logger.py
    # Frontend helper scripts (admin_api.py / stats_api.py / stats_writer.py):
    # always (re)install from the package into the data dir.
    for f in admin_api.py stats_api.py stats_writer.py; do
      install -m0644 ${config.services.litellm-cli.package}/data/$f ${cliDataDir}/$f
    done

    chown ${config.services.litellm-cli.user}:${config.services.litellm-cli.group} ${configFile} ${cliDataDir}/usage_logger.py ${cliDataDir}/admin_api.py ${cliDataDir}/stats_api.py ${cliDataDir}/stats_writer.py
    chmod 0644 ${configFile} ${cliDataDir}/usage_logger.py ${cliDataDir}/admin_api.py ${cliDataDir}/stats_api.py ${cliDataDir}/stats_writer.py

    # Drop the obsolete pre-refactor copy (config now lives in cliDataDir).
    rm -f ${stateDir}/config.yaml
  '';

  ##########################################################################
  # Frontend static files deployment (from litellm-cli package)
  ##########################################################################

  system.activationScripts.litellm-frontend = lib.stringAfter [ "users" ] ''
    set -euo pipefail
    mkdir -p /srv/www/ai/ui/playground

    # Deploy frontend static files from the package (always overwrite for reproducibility)
    for f in index.html litellm.js admin.js; do
      install -m0644 ${config.services.litellm-cli.package}/data/$f /srv/www/ai/$f
    done
    install -m0644 ${config.services.litellm-cli.package}/data/ui/playground/stats.json /srv/www/ai/ui/playground/stats.json

    chown -R ${config.services.litellm-cli.user}:${config.services.litellm-cli.group} /srv/www/ai
    chmod 0644 /srv/www/ai/index.html /srv/www/ai/litellm.js /srv/www/ai/admin.js /srv/www/ai/ui/playground/stats.json
  '';

  ##########################################################################
  # Caddy: expose LITELLM_MASTER_KEY so read-only routes can inject it
  ##########################################################################

  systemd.services.caddy.serviceConfig.EnvironmentFile =
    [ config.sops.secrets."providers.env".path ];

  ##########################################################################
  # LiteLLM service ordering + ExecStart
  ##########################################################################

  systemd.services.litellm = {
    after = [ "network.target" ];

    # usage_logger callback resolves via importlib through PYTHONPATH.
    environment = {
      PYTHONPATH = cliDataDir;
      LITELLM_USAGE_CALLBACK = "1";
    };

    serviceConfig = {
      ExecStart = lib.mkForce
        "${pkgs.litellm}/bin/litellm --host 127.0.0.1 --port ${toString litellmPort} --config ${configFile}";
      DynamicUser = lib.mkForce false;
      PrivateUsers = lib.mkForce false;
    };
  };
}
