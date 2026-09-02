# common/ai/litellm/litellm.nix
#
# LiteLLM gateway runtime using the native services.litellm module.
#
# Static config architecture (no runtime render, no litellm-cli at build):
#
#   committed source                    activation                    runtime
#   -----------------                   ----------                    -------
#   common/ai/litellm/config.yaml  ->   copy to                            litellm --config
#   (single source of truth,              /var/lib/litellm/config.yaml     /var/lib/litellm/config.yaml
#    hand-maintained)              +    install usage_logger.py
#                                      -> /srv/appdata/litellm/
#
# Ownership:
#   Nix owns: service definition + activation copy of the committed config.yaml
#   Repo owns: common/ai/litellm/config.yaml (the model list, aliases, fallbacks)
#   SOPS owns: providers.env (API keys / master key)
#
# litellm-cli is a purely MANUAL tool that edits the committed config.yaml. It is
# NOT invoked during nixos-rebuild or by any systemd unit.
#
{ config, lib, pkgs, ... }:

let
  litellmPort = 4000;
  stateDir = "/var/lib/litellm";
  # Committed static config — the single source of truth, copied at activation.
  staticConfig = ./config.yaml;
  cliDataDir = config.services.litellm-cli.dataDir;
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
      # model_list / model_alias / fallbacks live in the committed static
      # config.yaml copied to ${stateDir}/config.yaml (see activation below).
      model_list = [];
    };
  };

  ##########################################################################
  # Static config deployment (replaces litellm-cli render completely)
  ##########################################################################

  system.activationScripts.litellm-static-config = lib.stringAfter [ "users" ] ''
    set -euo pipefail
    mkdir -p ${stateDir} ${cliDataDir}

    # Handle dangling symlink /var/lib/litellm -> private/litellm (StateDirectory)
    if [ -L ${stateDir} ]; then
      mkdir -p /var/lib/private/litellm
    fi
    mkdir -p ${stateDir}

    # Copy the committed static config.yaml into the runtime location.
    cp -f ${staticConfig} ${stateDir}/config.yaml

    # usage_logger callback: ensure usage_logger.py lands in the PYTHONPATH dir.
    install -m644 ${config.services.litellm-cli.package}/data/usage_logger.py ${cliDataDir}/usage_logger.py

    chown ${config.services.litellm-cli.user}:${config.services.litellm-cli.group} ${stateDir}/config.yaml ${cliDataDir}/usage_logger.py
    chmod 0644 ${stateDir}/config.yaml ${cliDataDir}/usage_logger.py
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
        "${pkgs.litellm}/bin/litellm --host 127.0.0.1 --port ${toString litellmPort} --config ${stateDir}/config.yaml";
      DynamicUser = lib.mkForce false;
      PrivateUsers = lib.mkForce false;
    };
  };
}
