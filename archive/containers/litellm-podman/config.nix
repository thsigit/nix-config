# modules/ai/litellm-podman/config.nix
# LiteLLM config layer — inventory/policy management + renderer.
#
# Reuses the inventory/policy principle + renderer/CLI from pkgs/litellm-cli
# to drive the config.yaml consumed by modules/ai/litellm-podman/podman.nix. The
# systemd-native litellm module (./litellm) stays disabled; this module only
# produces data + tooling, never runs a LiteLLM process itself.

{ config, pkgs, lib, ... }:

let
  defaults = import ../../../settings;
  inherit (defaults) user ai;
  inherit (defaults.directories) appdata;

  stateDir   = "${appdata}/litellm";
  configFile = "${stateDir}/config.yaml";
  committedModelsJson = gw.modelsJsonPath;

  controller = pkgs.callPackage ../../../pkgs/litellm-cli { };
  gw = controller.mkGateway {
    stateDir = stateDir;
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
  options.ai.litellmConfig.enable = lib.mkEnableOption "LiteLLM config layer (inventory/policy + renderer)";

  config = lib.mkMerge [
    (lib.mkIf config.ai.litellmConfig.enable {
    # Install the admin CLI + renderer (litellm-render, -providers, -enable,
    # -disable, -add-provider, -missing, -doctor, -status).
    environment.systemPackages = gw.systemPackages;

    # Seed providers.json (from committed seed, if absent) + mirror models.json,
    # then render config.yaml so the Podman container has a fresh config on boot.
    systemd.tmpfiles.rules = [
      "d ${stateDir} 0755 ${user.name} ${user.group} -"
    ];

    system.activationScripts.litellm-config = lib.stringAfter [ "users" ] ''
      set -euo pipefail
      PATH="${lib.makeBinPath [ pkgs.jq pkgs.yq ]}:$PATH"
      ${gw.activationScript}
      # Render the config.yaml consumed by the Podman LiteLLM container.
      # Fail loudly (no `|| true`): a render failure means the gateway would
      # boot with a stale/empty config — better to abort activation.
      LITELLM_STATE_DIR=${stateDir} \
        LITELLM_PROVIDERS_JSON=${stateDir}/providers.json \
        LITELLM_MODELS_JSON=${stateDir}/models.json \
        LITELLM_ROUTER_YAML=${stateDir}/router.yaml \
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
        if [ -f ${stateDir}/models.json ]; then
          _tmp=$(mktemp ${stateDir}/models.json.XXXXXX)
          if ! jq -s '
            .[0] as $committed
            | .[1] as $runtime
            | ($runtime | with_entries(select(.value.source == "manual"))) as $manual
            | ($committed * $manual)
          ' ${committedModelsJson} ${stateDir}/models.json > "$_tmp"; then
            rm -f "$_tmp"
            echo "litellm-config: models.json merge failed; leaving runtime inventory untouched" >&2
            exit 1
          fi
          chown ${user.name}:${user.group} "$_tmp"
          mv "$_tmp" ${stateDir}/models.json
        fi

        # Touch providers.json to trigger path unit → re-render.
        touch ${stateDir}/providers.json
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

    # Re-render automatically whenever the admin edits providers.json / models.json
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
        PathChanged = [ "${stateDir}/providers.json" "${stateDir}/models.json" "${stateDir}/router.yaml" ];
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
