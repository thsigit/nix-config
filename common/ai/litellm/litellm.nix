# common/ai/litellm/litellm.nix
#
# LiteLLM gateway runtime using the native services.litellm module.
#
# Architecture (three-layer config):
#
#   Nix (eval time)              CLI (runtime)              Merge (startup)
#   ───────────────              ───────────────            ────────────────
#   services.litellm.settings    providers.json               litellm-cli render
#     ↓                           ↓                           ↓
#   /nix/store/config.yaml      data/models.json     →    /var/lib/litellm/config.yaml
#   (static defaults)            (discovered models)        (effective config)
#                                                                ↓
#                                                          litellm --config
#
# Ownership:
#   Nix owns: service definition, general_settings, litellm_settings, router_settings
#   CLI owns: model_list, model_alias, fallbacks
#   SOPS owns: providers.env (API keys)
#
{ config, lib, pkgs, ... }:

let
  litellmPort = 4000;
  stateDir = "/var/lib/litellm";
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
      handle / {
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
      model_list = [];
    };
  };

  ##########################################################################
  # Config render service (runs before litellm starts)
  ##########################################################################

  systemd.services.litellm-render = {
    description = "Render litellm effective config (providers.json + models.json)";
    wantedBy = [ "multi-user.target" ];
    before = [ "litellm.service" ];
    after = [ "network.target" "systemd-tmpfiles-setup.service" ];

    path = [ pkgs.coreutils pkgs.jq pkgs.bash ];

    serviceConfig = {
      Type = "oneshot";
      StateDirectory = "litellm";
      StateDirectoryMode = "0755";
      RuntimeDirectory = "litellm-cli";
      RuntimeDirectoryMode = "0755";
      ExecStart = "${config.services.litellm-cli.package}/bin/litellm-cli debug render";
    };
  };

  ##########################################################################
  # LiteLLM service ordering + ExecStart override
  ##########################################################################

  systemd.services.litellm = {
    after = [ "litellm-render.service" "network.target" ];
    requires = [ "litellm-render.service" ];

    serviceConfig = {
      ExecStart = lib.mkForce
        "${pkgs.litellm}/bin/litellm --host 127.0.0.1 --port ${toString litellmPort} --config ${stateDir}/config.yaml";
    };
  };
}
