# common/ai/litellm/litellm.nix
#
# LiteLLM gateway runtime using a native systemd service.
#
# Replaces the former litellm-podman.nix container-based approach.
# Configuration is owned by services.litellm-cli and rendered to:
#
#   services.litellm-cli.configFile
#
# This module:
#   - runs LiteLLM as a native systemd service
#   - consumes the litellm-cli rendered config via --config flag
#   - exposes LiteLLM through Caddy
#   - passes provider API keys + DB URL via environmentFiles
#
{ config, lib, pkgs, ... }:

let
  defaults = import ../../../settings;

  inherit (defaults) user;
  inherit (defaults.directories) appdata;

  litellmPort = 4000;
  litellmCli = config.services.litellm-cli;
  databaseEnv = "${appdata}/litellm/database.env";
in
{
  ##########################################################################
  # Assertions
  ##########################################################################

  assertions = [
    {
      assertion = litellmCli.enable;
      message = ''
        services.litellm requires services.litellm-cli.enable = true.

        The native service consumes the litellm-cli rendered config.
        Import common/ai/litellm/litellm-cli.nix before enabling this module.
      '';
    }
  ];

  ##########################################################################
  # Caddy reverse proxy
  ##########################################################################

  services.caddy.services.litellm = {
    port = litellmPort;
  };

  ##########################################################################
  # Native LiteLLM systemd service
  ##########################################################################

  systemd.services.litellm = {
    description = "LLM Gateway — LiteLLM native service";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "postgresql-setup.service" "litellm-db-password.service" ];
    requires = [ "postgresql-setup.service" ];

    path = [ pkgs.coreutils ];

    environment = {
      SCARF_NO_ANALYTICS = "True";
      DO_NOT_TRACK = "True";
      ANONYMIZED_TELEMETRY = "False";
      LITELLM_NON_ROOT = "true";
      LITELLM_UI_PATH = "/var/lib/litellm/ui";
      CUSTOM_TIKTOKEN_CACHE_DIR = "/var/lib/litellm/tiktoken-cache";
    };

    serviceConfig = {
      ExecStartPre = [
        "${pkgs.bash}/bin/bash -c 'mkdir -p /var/lib/litellm/{ui,tiktoken-cache}'"
        "${pkgs.bash}/bin/bash -c 'chmod -R u+rwX /var/lib/litellm/ui'"
      ];
      ExecStart = lib.concatStringsSep " " [
        "${pkgs.litellm}/bin/litellm"
        "--host 127.0.0.1"
        "--port ${toString litellmPort}"
        "--config ${litellmCli.configFile}"
      ];
      EnvironmentFile = [
        config.sops.secrets."providers.env".path
        databaseEnv
      ];
      WorkingDirectory = "/var/lib/litellm";
      StateDirectory = "litellm";
      RuntimeDirectory = "litellm";
      RuntimeDirectoryMode = "0755";
      UMask = "0077";
      PrivateTmp = true;
      DynamicUser = true;
      DevicePolicy = "closed";
      LockPersonality = true;
      PrivateUsers = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectControlGroups = true;
      RestrictNamespaces = true;
      RestrictRealtime = true;
      SystemCallArchitectures = "native";
      ProtectClock = true;
      ProtectProc = "invisible";
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
    };
  };
}
