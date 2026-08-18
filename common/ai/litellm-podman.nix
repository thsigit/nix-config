# common/ai/litellm-podman.nix
#
# LiteLLM gateway runtime using Podman.
#
# This module does NOT manage LiteLLM configuration.
# Configuration is owned by services.litellm-cli and rendered to:
#
#   services.litellm-cli.configFile
#
# This module only:
#   - runs the LiteLLM container
#   - mounts the rendered config.yaml
#   - provides persistent data/log directories
#   - exposes LiteLLM through Caddy
#
{ config, lib, ... }:

let
  defaults = import ../../settings;

  inherit (defaults) user;
  inherit (defaults.directories) appdata;

  litellm = config.services.litellm // { environmentFile = config.sops.secrets."providers.env".path; };
  litellmCli = config.services.litellm-cli;

  appdataDir = "${appdata}/litellm-podman";
in
{
  ##########################################################################
  # Runtime port
  ##########################################################################

  # The Podman runtime binds the loopback interface and Caddy proxies to it.
  # Explicitly pin to 4000 (the historical value) rather than inheriting the
  # native nixpkgs default (8080), which collides with services.llama-cpp.
  services.litellm.port = 4000;

  ##########################################################################
  # Native LiteLLM must never run
  ##########################################################################

  # Failing loudly beats silently overriding. If anything enables the native
  # LiteLLM systemd service, this configuration refuses to evaluate instead of
  # competing with the Podman runtime for port ${toString litellm.port}.
  assertions = [
    {
      assertion = !config.services.litellm.enable;
      message = ''
        services.litellm-podman requires the native LiteLLM service to be disabled.

        The Podman runtime owns LiteLLM on this host. Do NOT set
        services.litellm.enable = true — it would conflict with the container.
      '';
    }
    {
      assertion = litellmCli.enable;
      message = ''
        services.litellm-podman requires services.litellm-cli.enable = true.

        The Podman runtime consumes:
          services.litellm-cli.configFile

        Import common/ai/litellm-cli.nix before enabling the Podman runtime.
      '';
    }
  ];

  ##########################################################################
  # Caddy
  ##########################################################################

  services.caddy.services.litellm = {
    port = litellm.port;
  };

  ##########################################################################
  # Persistent directories
  ##########################################################################

  systemd.tmpfiles.rules = [
    "d ${appdataDir} 0755 ${user.name} ${user.group} -"
    "d ${appdataDir}/data 0755 ${user.name} ${user.group} -"
    "d ${appdataDir}/logs 0755 ${user.name} ${user.group} -"
  ];

  ##########################################################################
  # Podman container
  ##########################################################################

  virtualisation.oci-containers.containers.litellm = {
    image = "ghcr.io/berriai/litellm:v1.92.0";

    autoStart = true;

    extraOptions = [
      "--network=host"
      "--cap-drop=ALL"
      "--security-opt=no-new-privileges"
      "--health-cmd=python3 -c \"import urllib.request; urllib.request.urlopen('http://127.0.0.1:${toString litellm.port}/health/liveliness', timeout=5)\""
      "--health-interval=30s"
      "--health-retries=3"
      "--health-start-period=15s"
    ];

    # Keep systemd startup independent of the HTTP healthcheck.
    podman.sdnotify = "conmon";

    volumes = [
      "${litellmCli.configFile}:/app/config.yaml:ro"
      "${appdataDir}/data:/app/data"
      "${appdataDir}/logs:/app/logs"
    ];

    cmd = [
      "--config"
      "/app/config.yaml"
      "--host"
      litellm.host
      "--port"
      (toString litellm.port)
    ];

    environment = litellm.environment;

    environmentFiles =
      [ "${appdata}/litellm-podman/database.env" ]
      ++ lib.optional (litellm.environmentFile != null) litellm.environmentFile;
  };
}
