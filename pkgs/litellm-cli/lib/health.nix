# Health check logic — no NixOS dependencies, no provider-specific knowledge.
#
# The doctor derives its provider list and health endpoint entirely from
# providers.json (policy + connection + endpoints). It contains no hardcoded
# provider registry. Router validation reads router.yaml for capability
# routing checks.
#
# Usage:
#   healthLib = import "${controller}/lib/health.nix" { inherit lib pkgs; };
#   doctorScript = healthLib.mkDoctorScript { stateDir; providersRuntimePath; };
#   statusScript = healthLib.mkStatusScript { inherit stateDir; };

{ lib, pkgs }:

rec {
  mkDoctorScript = { stateDir, providersRuntimePath, routerRuntimePath ? "${stateDir}/router.yaml" }:
    pkgs.writeShellScriptBin "litellm-doctor" ''
      export PATH="${lib.makeBinPath [ pkgs.curl pkgs.jq pkgs.util-linux pkgs.yq ]}:$PATH"

      STATE_DIR="${stateDir}"
      PROVIDERS="${providersRuntimePath}"
      ROUTER="${routerRuntimePath}"
      MODELS="${stateDir}/models.json"
      STATE_FILE="$STATE_DIR/health.json"
      LOCK_DIR="''${XDG_RUNTIME_DIR:-/tmp}"
      LOCK_FILE="$LOCK_DIR/litellm-doctor.lock"

      exec 9>"$LOCK_FILE" 2>/dev/null || exec 9>&-
      if ! flock -n 9; then
        echo "Another litellm-doctor run is in progress. Exiting."
        exit 0
      fi

      if [ ! -f "$PROVIDERS" ]; then
        echo "litellm-doctor: $PROVIDERS not found"
        exit 1
      fi

      if [ ! -f "$STATE_FILE" ]; then
        echo '{}' > "$STATE_FILE"
      fi

      check_provider() {
        local name="$1"
        local api_base="$2"
        local key_env="$3"
        local models_path="$4"

        local api_key=""
        if [ "$key_env" = "none" ]; then
          api_key="__no_key_required__"
        else
          api_key="''${!key_env:-}"
        fi
        local status="unknown"
        local latency="0"
        local error=""
        local http_code=""
        local url="''${api_base}''${models_path}"

        if [ -z "$api_key" ]; then
          status="no_key"
          error="Environment variable $key_env is not set"
        else
          local start_time=$(date +%s%N)
          http_code=$(curl -s -o /dev/null -w "%{http_code}" \
            --max-time 10 \
            -H "Authorization: Bearer $api_key" \
            -H "Content-Type: application/json" \
            "$url" 2>/dev/null) || true
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
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo

      jq -r '
        to_entries[]
        | select(.value.enabled == true)
        | .key as $name
        | .value.connection as $conn
        | .value.endpoints.models as $mp
        | "\($name) \($conn.api_base) \($conn.api_key_env // "none") \($mp)"
      ' "$PROVIDERS" | \
      while read -r name api_base key_env models_path; do
        check_provider "$name" "$api_base" "$key_env" "$models_path"
      done

      echo
      echo "State saved to: $STATE_FILE"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

      jq -r '
        "Total: \(length) | Healthy: \([.[] | select(.status == "healthy")] | length) | No key: \([.[] | select(.status == "no_key")] | length) | Errors: \([.[] | select(.status != "healthy" and .status != "no_key")] | length)"
      ' "$STATE_FILE"

      # ── Router validation ──────────────────────────────────────────
      echo
      echo "litellm router check — capability routing validation"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo

      if [ ! -f "$ROUTER" ]; then
        echo "  ○ No router.yaml found — routing not configured"
      else
        ROUTER_JSON=$(yq . "$ROUTER" 2>/dev/null) || {
          echo "  ✗ Failed to parse router.yaml (invalid YAML)"
          echo
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          exit 0
        }

        PROVIDER_NAMES=$(jq -r 'keys | .[]' "$PROVIDERS")
        ENABLED_PROVIDERS=$(jq -r 'to_entries[] | select(.value.enabled == true) | .key' "$PROVIDERS")

        CAPS=$(echo "$ROUTER_JSON" | jq '.capabilities // {}')
        MODELS_DEF=$(echo "$ROUTER_JSON" | jq '.models // {}')
        MODEL_KEYS=$(echo "$MODELS_DEF" | jq -r 'keys | .[]' 2>/dev/null || true)
        ERROR_FILE=$(mktemp)

        # ── Check 1: every capability primary/fallback references a defined logical model
        echo "$CAPS" | jq -r '
          to_entries[] |
          .key as $cap |
          .value.primary as $primary |
          "\($cap)|\($primary)|primary",
          (.value.fallback // [] | .[] | "\($cap)|\(.)|fallback")
        ' 2>/dev/null | while IFS='|' read -r cap ref kind; do
          if ! echo "$MODEL_KEYS" | grep -qxF "$ref"; then
            echo "  ✗ Capability '$cap': $kind model '$ref' not defined in router.models"
            echo 1 >> "$ERROR_FILE"
          fi
        done

        # ── Check 2: every logical model references valid provider+model
        echo "$MODELS_DEF" | jq -r '
          to_entries[] |
          "\(.key)|\(.value.provider)|\(.value.model)"
        ' 2>/dev/null | while IFS='|' read -r logical prov mdl; do
          if ! echo "$PROVIDER_NAMES" | grep -qxF "$prov"; then
            echo "  ✗ Logical model '$logical': provider '$prov' not found in providers.json"
            echo 1 >> "$ERROR_FILE"
          elif ! echo "$ENABLED_PROVIDERS" | grep -qxF "$prov"; then
            echo "  ⚠ Logical model '$logical': provider '$prov' exists but is disabled"
          else
            if ! jq -e ".[\"$prov\"].models // [] | map(.id) | index(\"$mdl\")" "$MODELS" >/dev/null 2>&1; then
              echo "  ⚠ Logical model '$logical': model '$mdl' not found for provider '$prov' in models.json"
            fi
          fi
        done

        # ── Check 3: every capability resolves to at least one usable model
        echo "$CAPS" | jq -r '
          to_entries[] |
          "\(.key)|\(.value.primary)"
        ' 2>/dev/null | while IFS='|' read -r cap primary; do
          prov=$(echo "$MODELS_DEF" | jq -r ".[\"$primary\"].provider // \"\"")
          if [ -n "$prov" ] && ! echo "$ENABLED_PROVIDERS" | grep -qxF "$prov"; then
            echo "  ⚠ Capability '$cap': primary relies on disabled provider '$prov'"
          fi
        done

        ERRORS=$(wc -l < "$ERROR_FILE" 2>/dev/null || echo 0)
        rm -f "$ERROR_FILE"
        if [ "$ERRORS" -eq 0 ]; then
          echo "  ✓ All capabilities valid"
        fi

        echo
        # ── Summary ──
        cap_count=$(echo "$ROUTER_JSON" | jq '.capabilities | length')
        model_count=$(echo "$ROUTER_JSON" | jq '.models | length')
        echo "  Router: $cap_count capabilities, $model_count logical models"
      fi

      echo
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    '';

  mkStatusScript = { stateDir }:
    pkgs.writeShellScriptBin "litellm-status" ''
      export PATH="${lib.makeBinPath [ pkgs.jq pkgs.yq ]}:$PATH"
      STATE_FILE="${stateDir}/health.json"
      ROUTER="${stateDir}/router.yaml"
      PROVIDERS="${stateDir}/providers.json"

      if [ ! -f "$STATE_FILE" ]; then
        echo "No health data yet. Run: litellm-doctor"
        exit 0
      fi

      echo "litellm status — cached provider health"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
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

      # ── Routing table ──────────────────────────────────────────────
      echo
      if [ ! -f "$ROUTER" ]; then
        echo "No router.yaml — routing not configured"
      else
        ROUTER_JSON=$(yq . "$ROUTER" 2>/dev/null) || {
          echo "Failed to parse router.yaml"
          exit 0
        }

        echo "litellm status — routing table"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        printf "  %-20s %-24s %s\n" "Capability" "Primary" "Fallback"
        printf "  %-20s %-24s %s\n" "──────────" "───────" "────────"
        echo "$ROUTER_JSON" | jq -r '
          .capabilities | to_entries[] |
          .key as $cap |
          .value.primary as $primary |
          (.value.fallback // []) |
          if length > 0 then
            "\($cap) \($primary) \(join(", "))"
          else
            "\($cap) \($primary) —"
          end
        ' 2>/dev/null | while read -r cap primary fallback; do
          printf "  %-20s %-24s %s\n" "$cap" "$primary" "$fallback"
        done

        echo
        model_count=$(echo "$ROUTER_JSON" | jq '.models | length')
        cap_count=$(echo "$ROUTER_JSON" | jq '.capabilities | length')
        echo "  $cap_count capabilities, $model_count logical models"
      fi
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    '';
}
