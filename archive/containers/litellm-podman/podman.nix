# modules/ai/litellm-podman/podman.nix
# LiteLLM gateway running as a Podman container (upstream image)
#
# Replaces the systemd-native litellm module as the active runtime
# (2026-07-18). The operational wrapper layer (inventory/policy + renderer)
# lives in pkgs/litellm-cli and writes the mounted config.yaml.

{ config, pkgs, lib, ... }:

let
  defaults = import ../../../settings;
  inherit (defaults) user ai;
  inherit (defaults.directories) appdata;

  appdataDir = "${appdata}/litellm";
  configFile  = "${appdataDir}/config.yaml";
in

{
  options.ai.podmanLitellm.enable = lib.mkEnableOption "LiteLLM gateway (Podman)";

  config = lib.mkIf config.ai.podmanLitellm.enable {
    services.caddy.services.litellm = {
      port = 4000;
    };

    virtualisation.oci-containers.containers.litellm = {
      # Pinned stable release. The :main nightly is a dev build that hangs the
      # event loop on large model_list configs and re-runs a pip bootstrap on
      # every start. v1.92.0 boots cleanly with our full inventory.
      # Bump cadence: upgrade on a per-release basis after smoke-testing the
      # new tag against our full inventory (`/v1/models` + a real chat call).
      # Avoid :latest/:main — they drift and broke us before.
      image = "ghcr.io/berriai/litellm:v1.92.0";
      # Bind loopback only: Caddy runs on the host and proxies to
      # 127.0.0.1:4000 (services.caddy.services.litellm.port = 4000). Avoid
      # exposing the gateway to the LAN.
      extraOptions = [
        "--network" "host"
        # Hardening: drop all capabilities + forbid privilege escalation.
        "--cap-drop=ALL"
        "--security-opt=no-new-privileges"
        # Health probe: mark the unit ready only when the gateway actually
        # serves /health/liveliness (checked from inside the container via
        # host networking). Python is guaranteed present in the image.
        "--health-cmd=python3 -c \"import urllib.request; urllib.request.urlopen('http://127.0.0.1:4000/health/liveliness', timeout=5)\""
        "--health-interval=30s"
        "--health-retries=3"
        "--health-start-period=15s"
      ];
      podman = {
        # Gate the unit's ready-state on the container healthcheck passing.
        sdnotify = "healthy";
      };
      # Mount our rendered config at the path v1.92.0's entrypoint expects.
      volumes = [
        "${configFile}:/app/config.yaml:ro"
        "${appdataDir}/data:/app/data"
        "${appdataDir}/logs:/app/logs"
      ];
      # CRITICAL: the upstream entrypoint (docker/prod_entrypoint.sh) just runs
      # `litellm "$@"` with no config path of its own. It does NOT
      # auto-read /app/config.yaml, and LITELLM_CONFIG is not a variable the
      # CLI honours (the flag is --config). We dropped this `cmd` in
      # 1faf3b3 under the mistaken belief the image would load the mounted
      # file automatically — without it the proxy boots with an empty
      # model_list ("/v1/models" -> {"data":[]}, "/model/info" ->
      # "LLM Model List not loaded in") and every chat completion fails with
      # "Invalid model name". The mounted file is correct; it just must be
      # passed explicitly. (LITELLM_CONFIG env removed for the same reason.)
      cmd = [ "--config" "/app/config.yaml" "--host" "127.0.0.1" "--port" "4000" ];
      environment = {
        LITELLM_DISABLE_CHAT_CACHE = "true";
      };
      # Mount sops-derived env (master key, provider keys) into the container.
      environmentFiles = [
        config.sops.secrets."litellm.env".path
      ];
      autoStart = true;
    };

    systemd.services."podman-litellm" = {
      serviceConfig = {
        RemainAfterExit = true;
      };
    };

    systemd.tmpfiles.rules = [
      "d ${ai.root} 0755 ${user.name} ${user.group} -"
      "d ${appdataDir} 0755 ${user.name} ${user.group} -"
      "d ${appdataDir}/data 0755 ${user.name} ${user.group} -"
      "d ${appdataDir}/logs 0755 ${user.name} ${user.group} -"
    ];

    # Seed a minimal placeholder config so the container can start before the
    # wrapper layer renders the real inventory/policy-driven config.yaml.
    system.activationScripts.podman-litellm-config = lib.stringAfter [ "users" ] ''
      set -euo pipefail
      if [ ! -f ${configFile} ]; then
        mkdir -p ${appdataDir}
        cat > ${configFile} <<YAML
model_list: []
litellm_settings:
  drop_params: true
  json_logs: true
general_settings:
  master_key: os.environ/LITELLM_MASTER_KEY
YAML
        chown ${user.name}:${user.group} ${configFile}
      fi
    '';
  };
}
