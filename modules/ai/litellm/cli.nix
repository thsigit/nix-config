# modules/ai/litellm/cli.nix
# CLI tools for managing providers at runtime

{ config, lib, pkgs, ... }:

let
  dataDir = "/srv/appdata/litellm";

  enableScript = pkgs.writeShellScriptBin "litellm-enable-provider" ''
    export PATH="${lib.makeBinPath [ pkgs.jq ]}:$PATH"

    if [ "$(id -u)" -ne 0 ]; then
      echo "Error: this command must be run as root (sudo)"
      exit 1
    fi

    if [ $# -eq 0 ]; then
      echo "Usage: litellm-enable-provider <provider-name>"
      echo "Example: litellm-enable-provider kenari"
      exit 1
    fi

    PROVIDER="$1"
    ENABLED_FILE="${dataDir}/providers-enabled.json"

    if [ ! -f "$ENABLED_FILE" ]; then
      echo "Error: $ENABLED_FILE not found"
      exit 1
    fi

    # Check if already enabled
    if jq -e ".\"$PROVIDER\" == true" "$ENABLED_FILE" >/dev/null 2>&1; then
      echo "Provider '$PROVIDER' is already enabled"
      exit 0
    fi

    # Add provider to enabled list
    jq ".\"$PROVIDER\" = true" "$ENABLED_FILE" > "$ENABLED_FILE.tmp" && mv "$ENABLED_FILE.tmp" "$ENABLED_FILE"

    echo "Enabled provider: $PROVIDER"
    echo "Restarting litellm..."
    systemctl restart litellm
    echo "Done. Provider '$PROVIDER' is now enabled."
  '';

  disableScript = pkgs.writeShellScriptBin "litellm-disable-provider" ''
    export PATH="${lib.makeBinPath [ pkgs.jq ]}:$PATH"

    if [ "$(id -u)" -ne 0 ]; then
      echo "Error: this command must be run as root (sudo)"
      exit 1
    fi

    if [ $# -eq 0 ]; then
      echo "Usage: litellm-disable-provider <provider-name>"
      echo "Example: litellm-disable-provider kenari"
      exit 1
    fi

    PROVIDER="$1"
    ENABLED_FILE="${dataDir}/providers-enabled.json"

    if [ ! -f "$ENABLED_FILE" ]; then
      echo "Error: $ENABLED_FILE not found"
      exit 1
    fi

    # Check if provider is in the list
    if ! jq -e "has(\"$PROVIDER\")" "$ENABLED_FILE" >/dev/null 2>&1; then
      echo "Provider '$PROVIDER' is not in the enabled list"
      exit 0
    fi

    # Remove provider from enabled list
    jq "del(.\"$PROVIDER\")" "$ENABLED_FILE" > "$ENABLED_FILE.tmp" && mv "$ENABLED_FILE.tmp" "$ENABLED_FILE"

    echo "Disabled provider: $PROVIDER"
    echo "Restarting litellm..."
    systemctl restart litellm
    echo "Done. Provider '$PROVIDER' is now disabled."
  '';

  listScript = pkgs.writeShellScriptBin "litellm-providers" ''
    export PATH="${lib.makeBinPath [ pkgs.jq ]}:$PATH"

    ENABLED_FILE="${dataDir}/providers-enabled.json"
    MODELS_FILE="${dataDir}/models.json"

    echo "litellm providers — provider registry"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo

    if [ ! -f "$MODELS_FILE" ]; then
      echo "No models data yet. Run: nixos-rebuild switch"
      exit 0
    fi

    # Get all providers from models.json
    ALL_PROVIDERS=$(jq -r '[.[] | .litellm_params.model | split("/")[0]] | unique | .[]' "$MODELS_FILE")

    # Get enabled providers
    if [ -f "$ENABLED_FILE" ]; then
      ENABLED=$(jq -r 'keys[]' "$ENABLED_FILE" 2>/dev/null || echo "")
    else
      ENABLED=""
    fi

    # Count models per provider
    for provider in $ALL_PROVIDERS; do
      MODEL_COUNT=$(jq --arg p "$provider" '[.[] | select(.litellm_params.model | startswith($p + "/"))] | length' "$MODELS_FILE")

      if [ -n "$ENABLED" ] && echo "$ENABLED" | grep -q "^$provider$"; then
        icon="✓"
        status="enabled"
      else
        icon="○"
        status="disabled"
      fi
      printf "  %s %-16s %s (%s models)\n" "$icon" "$provider" "$status" "$MODEL_COUNT"
    done

    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Use litellm-enable-provider / litellm-disable-provider to manage"
  '';

in
{
  environment.systemPackages = [
    enableScript
    disableScript
    listScript
  ];
}
