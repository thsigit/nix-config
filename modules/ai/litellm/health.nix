# modules/ai/litellm/health.nix
# Provider health monitoring for the AI gateway

{ config, lib, pkgs, ... }:

let
  cfg = config.services.litellm;
  dataDir = "/srv/appdata/litellm";

  enabledProvidersJson = "${dataDir}/providers-enabled.json";

  # Provider registry — mirrors providers-open.nix and providers-restricted.nix
  providers = {
    aihubmix = {
      env = "AIHUBMIX_API_KEY";
      api = "https://aihubmix.com/v1/models";
    };
    cohere = {
      env = "COHERE_API_KEY";
      api = "https://api.cohere.com/v2/";
    };
    nvidia = {
      env = "NVIDIA_API_KEY";
      api = "https://integrate.api.nvidia.com/v1/models";
    };
    openrouter = {
      env = "OPENROUTER_API_KEY";
      api = "https://openrouter.ai/api/v1/models";
    };
    kenari = {
      env = "KENARI_API_KEY";
      api = "https://api.kenari.com/v1/models";
    };
    zai = {
      env = "ZHIPU_API_KEY";
      api = "https://open.bigmodel.cn/api/paas/v4/models";
    };
    fireworks-ai = {
      env = "FIREWORKS_API_KEY";
      api = "https://api.fireworks.ai/inference/v1/models";
    };
    gemini = {
      env = "GEMINI_API_KEY";
      api = "https://generativelanguage.googleapis.com/v1beta/models";
    };
  };

  providerJson = pkgs.writeText "litellm-providers.json"
    (builtins.toJSON providers);

  doctorScript = pkgs.writeShellScriptBin "litellm-doctor" ''
    export PATH="${lib.makeBinPath [ pkgs.curl pkgs.jq ]}:$PATH"

    PROVIDERS="${providerJson}"
    STATE_FILE="${dataDir}/health.json"

    # Read enabled providers from JSON
    ENABLED_FILE="${enabledProvidersJson}"
    if [ -f "$ENABLED_FILE" ]; then
      ENABLED=$(cat "$ENABLED_FILE")
    else
      ENABLED="{}"
    fi

    # Filter providers to only enabled ones
    if [ "$ENABLED" = "{}" ]; then
      CHECK_PROVIDERS="$PROVIDERS"
    else
      CHECK_PROVIDERS=$(jq --argjson enabled "$ENABLED" '
        to_entries | map(select(
          (.key | split("/")[0]) as $name |
          ($enabled | has($name)) and ($enabled[$name] == true)
        )) | from_entries
      ' "$PROVIDERS")
    fi

    check_provider() {
      local name="$1"
      local env_var="$2"
      local api_url="$3"

      local api_key="''${!env_var:-}"
      local status="unknown"
      local latency="0"
      local error=""
      local http_code=""

      if [ -z "$api_key" ]; then
        status="no_key"
        error="Environment variable $env_var is not set"
      else
        local start_time=$(date +%s%N)
        http_code=$(curl -s -o /dev/null -w "%{http_code}" \
          --max-time 10 \
          -H "Authorization: Bearer $api_key" \
          -H "Content-Type: application/json" \
          "$api_url" 2>/dev/null) || true
        local end_time=$(date +%s%N)
        latency=$(( (end_time - start_time) / 1000000 ))

        if [ "$http_code" = "200" ]; then
          status="healthy"
        elif [ "$http_code" = "401" ] || [ "$http_code" = "403" ]; then
          status="auth_error"
          error="Invalid or expired API key (HTTP $http_code)"
        elif [ "$http_code" = "429" ]; then
          status="rate_limited"
          error="Rate limited (HTTP 429)"
        elif [ "$http_code" = "000" ]; then
          status="unreachable"
          error="Connection failed or timed out"
        else
          status="error"
          error="Unexpected response (HTTP $http_code)"
        fi
      fi

      # Update state
      local tmp=$(mktemp)
      jq --arg name "$name" \
         --arg status "$status" \
         --argjson latency "$latency" \
         --arg error "$error" \
         --arg http_code "''${http_code:-0}" \
         --arg checked_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
         '.[$name] = {
           status: $status,
           latency_ms: $latency,
           error: $error,
           http_code: ($http_code | tonumber),
           checked_at: $checked_at
         }' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"

      # Print result
      local icon
      case "$status" in
        healthy)    icon="✓" ;;
        no_key)     icon="○" ;;
        auth_error) icon="✗" ;;
        rate_limited) icon="⚠" ;;
        unreachable) icon="✗" ;;
        *)          icon="?" ;;
      esac

      printf "  %s %-16s %s" "$icon" "$name" "$status"
      if [ "$latency" -gt 0 ]; then
        printf " (%dms)" "$latency"
      fi
      if [ -n "$error" ]; then
        printf " — %s" "$error"
      fi
      echo
    }

    echo "litellm doctor — provider health check"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo

    # Initialize state file if missing
    if [ ! -f "$STATE_FILE" ]; then
      echo '{}' > "$STATE_FILE"
    fi

    # Read providers from JSON and check each
    jq -r 'to_entries[] | "\(.key) \(.value.env) \(.value.api)"' "$CHECK_PROVIDERS" | \
    while read -r name env_var api_url; do
      check_provider "$name" "$env_var" "$api_url"
    done

    echo
    echo "State saved to: $STATE_FILE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Summary from state file
    jq -r '
      "Total: \(length) | Healthy: \([.[] | select(.status == "healthy")] | length) | No key: \([.[] | select(.status == "no_key")] | length) | Errors: \([.[] | select(.status != "healthy" and .status != "no_key")] | length)"
    ' "$STATE_FILE"
  '';

  # Quick status without network calls
  statusScript = pkgs.writeShellScriptBin "litellm-status" ''
    export PATH="${lib.makeBinPath [ pkgs.jq ]}:$PATH"
    STATE_FILE="${dataDir}/health.json"

    if [ ! -f "$STATE_FILE" ]; then
      echo "No health data yet. Run: litellm-doctor"
      exit 0
    fi

    echo "litellm status — cached provider health"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo

    jq -r '
      to_entries[] |
      .value.status as $s |
      .key as $name |
      (if $s == "healthy" then "✓" elif $s == "no_key" then "○" else "✗" end) as $icon |
      "\($icon) \($name)\(" " * (16 - ($name | length))) \($s)\(if .value.latency_ms > 0 then " (\(.value.latency_ms)ms)" else "" end)\(if .value.error != "" then " — \(.value.error)" else "" end)"
    ' "$STATE_FILE" 2>/dev/null || echo "Corrupt state file. Run: litellm-doctor"

    echo
    jq -r '
      "Total: \(length) | Healthy: \([.[] | select(.status == "healthy")] | length) | No key: \([.[] | select(.status == "no_key")] | length) | Errors: \([.[] | select(.status != "healthy" and .status != "no_key")] | length)"
    ' "$STATE_FILE" 2>/dev/null
  '';

in
{
  options.services.litellm.health = {
    enable = lib.mkEnableOption "provider health monitoring";
  };

  config = lib.mkIf cfg.health.enable {
    environment.systemPackages = [
      doctorScript
      statusScript
    ];

    systemd.services.litellm-doctor = {
      description = "LiteLLM provider health check";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${doctorScript}/bin/litellm-doctor";
      };
    };

    systemd.timers.litellm-doctor = {
      description = "Periodic provider health check";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "hourly";
        Persistent = true;
      };
    };
  };
}
