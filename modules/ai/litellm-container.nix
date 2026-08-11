# modules/ai/litellm-container.nix
# LiteLLM gateway (Podman container) — runtime + config layer.
#
# ACTIVE runtime. The systemd-native ./litellm.nix is disabled.
# Toggled on via modules/ai/default.nix:
#   ai.podmanLitellm.enable = true;
#   ai.litellmConfig.enable = true;
#
# Volumes live under /srv/appdata/litellm-container.
# DB credentials are provided by modules/db: database.env (DATABASE_URL) is
# generated at activation and mounted here alongside the sops litellm.env.

{ config, pkgs, lib, litellmCli, ... }:

let
  defaults = import ../../settings;
  inherit (defaults) user ai;
  inherit (defaults.directories) appdata;

  appdataDir = "${appdata}/litellm-container";
  configFile = "${appdataDir}/config.yaml";
  committedModelsJson = gw.modelsJsonPath;

  controller = pkgs.callPackage litellmCli { };
  gw = controller.mkGateway {
    stateDir = appdataDir;
    configYamlPath = configFile;
    providersEnvFile = config.sops.secrets."providers.env".path;
    user = user.name;
    group = user.group;
  };

  # Only restart the container when the Podman runtime is actually enabled
  # (keeps the wrapper decoupled for option b/c later).
  podmanEnabled = config.ai.podmanLitellm.enable or false;

  # Restart the gateway after a (re)render, tolerating a not-yet-running container.
  # Notifies via logger (journal/audit trail) only — no wall (it can freeze terminals).
  # Debounced (flock + sleep): rapid sequential renders coalesce into ONE restart
  # instead of restarting the container once per file change.
  restartScript = pkgs.writeShellScript "litellm-render-restart" ''
    set -eu
    MSG="litellm-config: inventory/policy/routing changed — restarting podman-litellm gateway (brief outage)"
    ${pkgs.util-linux}/bin/logger -t litellm-config "$MSG" || true
    # Debounce: if another restart is already queued within the window, skip.
    exec 9>/run/litellm-render-restart.lock
    if ! ${pkgs.util-linux}/bin/flock -n 9; then
      exit 0
    fi
    sleep 5
    # Restart via systemd — podman's named-container registry isn't populated
    # when the container was started by the systemd unit via conmon/crun directly.
    if systemctl is-active --quiet podman-litellm.service 2>/dev/null; then
      systemctl try-restart podman-litellm.service || true
    fi
  '';
in
{
  options.ai.podmanLitellm.enable = lib.mkEnableOption "LiteLLM gateway (Podman)";
  options.ai.litellmConfig.enable = lib.mkEnableOption "LiteLLM config layer (inventory/policy + renderer)";

  config = lib.mkMerge [
    # ---- runtime: the gateway container ----
    (lib.mkIf config.ai.podmanLitellm.enable {
      services.caddy.services.litellm = { port = 4000; };

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
        # CLI honours (the flag is --config). Without this `cmd` the proxy boots
        # with an empty model_list ("/v1/models" -> {"data":[]}, "/model/info" ->
        # "LLM Model List not loaded in") and every chat completion fails with
        # "Invalid model name". The mounted file is correct; it just must be
        # passed explicitly. (LITELLM_CONFIG env removed for the same reason.)
        cmd = [ "--config" "/app/config.yaml" "--host" "127.0.0.1" "--port" "4000" ];
        environment = {
          LITELLM_DISABLE_CHAT_CACHE = "true";
        };
        # Mount sops-derived env (master key, provider keys) + the db module's
        # generated DATABASE_URL into the container.
        environmentFiles = [
          config.sops.secrets."litellm.env".path
          "${appdataDir}/database.env"
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
    })

    # ---- config layer: inventory/policy management + renderer ----
    (lib.mkIf config.ai.litellmConfig.enable {
      # Install the admin CLI + renderer (litellm-render, -providers, -enable,
      # -disable, -add-provider, -missing, -doctor, -status).
      environment.systemPackages = gw.systemPackages;

      # Seed gateway.json (from committed seed, if absent) + mirror models.json,
      # then render config.yaml so the Podman container has a fresh config on boot.
      systemd.tmpfiles.rules = [
        "d ${appdataDir} 0755 ${user.name} ${user.group} -"
      ];

      system.activationScripts.litellm-config = lib.stringAfter [ "users" ] ''
        set -euo pipefail
        PATH="${lib.makeBinPath [ pkgs.jq pkgs.yq ]}:$PATH"
        ${gw.activationScript}
        # Render the config.yaml consumed by the Podman LiteLLM container.
        # Fail loudly (no `|| true`): a render failure means the gateway would
        # boot with a stale/empty config — better to abort activation.
        LITELLM_STATE_DIR=${appdataDir} \
          LITELLM_GATEWAY_JSON=${appdataDir}/gateway.json \
          LITELLM_MODELS_JSON=${appdataDir}/models.json \
          LITELLM_CONFIG_YAML=${configFile} \
          PATH="${lib.makeBinPath [ pkgs.jq pkgs.yq ]}:$PATH" \
          ${gw.renderScript}/bin/litellm-render
      '';

      # Run doctor checks on a timer so health.json stays fresh.
      systemd.services.litellm-doctor = {
        description = "LiteLLM provider health check";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${gw.doctorScript}/bin/litellm-doctor";
          EnvironmentFile = config.sops.secrets."providers.env".path;
        };
      };

      systemd.timers.litellm-doctor = {
        description = "Hourly LiteLLM provider health check";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "hourly";
          Persistent = true;
          # Stagger so hosts don't all fire at the same minute.
          RandomizedDelaySec = "5m";
        };
      };

      # Daily fetch of free models from models.dev into committed inventory,
      # then merge into runtime (preserving manual entries) and trigger re-render.
      systemd.services.fetch-models = {
        description = "Fetch free LLM model snapshot from models.dev";
        serviceConfig = {
          Type = "oneshot";
          User = "${user.name}";
          WorkingDirectory = "${ai.repo}";
        };
        path = with pkgs; [ jq ];
        script = ''
          set -euo pipefail
          # Fetch models.dev → committed inventory (auto-commits if changed).
          ${gw.fetchScript}/bin/fetch-models

          # Merge committed inventory into runtime, preserving manual entries.
          # Atomic write: build into a temp file, only replace on success so a
          # failed merge never truncates models.json.
          if [ -f ${appdataDir}/models.json ]; then
            _tmp=$(mktemp ${appdataDir}/models.json.XXXXXX)
            if ! jq -s '
              .[0] as $committed
              | .[1] as $runtime
              | ($runtime | with_entries(select(.value.source == "manual"))) as $manual
              | ($committed * $manual)
            ' ${committedModelsJson} ${appdataDir}/models.json > "$_tmp"; then
              rm -f "$_tmp"
              echo "litellm-config: models.json merge failed; leaving runtime inventory untouched" >&2
              exit 1
            fi
            chown ${user.name}:${user.group} "$_tmp"
            mv "$_tmp" ${appdataDir}/models.json
          fi

          # Touch models.json to trigger path unit → re-render.
          touch ${appdataDir}/models.json
        '';
      };

      systemd.timers.fetch-models = {
        description = "Daily fetch of free LLM model snapshot";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
      };

      # Re-render automatically whenever the admin edits gateway.json / models.json
      # (the inputs). The rendered output (config.yaml) is NOT watched, to avoid a
      # render→change→render loop.
      systemd.services.litellm-render = {
        description = "Render LiteLLM config.yaml from inventory/policy";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${gw.renderScript}/bin/litellm-render";
        };
      };

      systemd.paths.litellm-render = {
        description = "Trigger config render on inventory/policy change";
        wantedBy = [ "paths.target" ];
        pathConfig = {
          PathChanged = [ "${appdataDir}/gateway.json" "${appdataDir}/models.json" ];
        };
      };
    })

    # Restart-on-render glue: only active when the Podman runtime is enabled.
    (lib.mkIf (config.ai.litellmConfig.enable && podmanEnabled) {
      systemd.services.litellm-render = {
        after = [ "podman-litellm.service" ];
        serviceConfig = {
          ExecStartPost = lib.mkAfter [ "${restartScript}" ];
        };
      };
    })
  ];
}
