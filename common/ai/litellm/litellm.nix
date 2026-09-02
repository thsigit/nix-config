# common/ai/litellm/litellm.nix
#
# LiteLLM gateway runtime using the native services.litellm module.
#
# Static config architecture (no runtime render, no litellm-cli at build):
#
#   committed seed                    first activation                 runtime
#   ----------------                  ----------------                 -------
#   common/ai/litellm/config.yaml ->  copy ONLY if missing        ->   litellm --config
#   (first boot default)               /srv/appdata/litellm/config.yaml /srv/appdata/litellm/config.yaml
#                                +   install usage_logger.py
#                                     -> /srv/appdata/litellm/
#
# The runtime config.yaml is ADMIN-EDITABLE and lives in /srv/appdata/litellm,
# the persistent replacement dir (survives /var deletion). It does NOT
# participate in nixos-rebuild: once seeded, rebuilds never overwrite it.
# The committed copy in this repo is only a first-boot default.
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

  services.caddy.services.litellm = {
    port = litellmPort;
    preConfig = ''
      @frontend path / /litellm.js /ui/playground/*
      handle @frontend {
        root * /srv/www/litellm
        file_server
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

    settings = {
      general_settings = {
        master_key = "os.environ/LITELLM_MASTER_KEY";
      };
      litellm_settings = {
        json_logs = true;
        drop_params = true;
      };
      router_settings = {
        routing_strategy = "usage-based-routing";
        num_retries = 2;
        enable_pre_call_checks = true;
      };
      # model_list / model_alias / fallbacks live in the admin-edited
      # ${configFile} (seeded once, then handled at the persistence layer).
      model_list = [];
    };
  };

  ##########################################################################
  # Static config deployment (replaces litellm-cli render completely)
  ##########################################################################

  system.activationScripts.litellm-static-config = lib.stringAfter [ "users" ] ''
    set -euo pipefail
    mkdir -p ${cliDataDir}

    # Seed the admin-editable config.yaml from the committed copy ONLY on first
    # deployment. Once present it is edited by hand / litellm-cli and must
    # survive rebuilds untouched.
    if [ ! -f ${configFile} ]; then
      install -m0644 ${staticConfig} ${configFile}
    fi

    # usage_logger callback: always (re)install from the package.
    install -m0644 ${config.services.litellm-cli.package}/data/usage_logger.py ${cliDataDir}/usage_logger.py

    chown ${config.services.litellm-cli.user}:${config.services.litellm-cli.group} ${configFile} ${cliDataDir}/usage_logger.py
    chmod 0644 ${configFile} ${cliDataDir}/usage_logger.py

    # Drop the obsolete pre-refactor copy (config now lives in cliDataDir).
    rm -f ${stateDir}/config.yaml
  '';

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