#!/usr/bin/env bash
# fetch-models — discover free models and write the canonical inventory.
#
# Output: pkgs/litellm-cli/data/models-dev.json
#   Single canonical inventory of every model the gateway knows about,
#   regardless of how it was discovered (models.dev or declared).
#   Contains NO secrets. Safe to commit.
#
# Each model carries provenance (origin):
#   - discovered:  fetched from models.dev (with discovered_at timestamp)
#   - declared:    admin-owned backend models (gemini, ollama, ...)
#   - manual:      added at runtime via litellm-add-provider (no rebuild)
#
# Pipeline:
#   models.dev (external API)
#       -> fetch-models
#       -> models.json   (canonical inventory)
#
# Declared models (gemini, ollama) are NOT discovered from models.dev;
# they are appended here so the inventory stays a single file.

set -euo pipefail

REPO="$(git rev-parse --show-toplevel 2>/dev/null)" || true
if [ -z "$REPO" ] || ! git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
  echo "fetch-models: ERROR — could not locate git repo root" >&2
  exit 1
fi

SNAPSHOT="$REPO/pkgs/litellm-cli/data/models-dev.json"

# Normalization: keep only free models, reshape into the canonical inventory.
# Each provider becomes { source: "models.dev", models: [ { id, ...caps, origin } ] }.
curl -sfL 'https://models.dev/api.json' |
  jq '
    with_entries(
      .value.models = (.value.models | with_entries(
        select(.value.cost.input == 0 and .value.cost.output == 0)
      ))
    )
    | with_entries(select(.value.models | length > 0))
    | to_entries | map({
        key: .key,
        value: {
          source: "models.dev",
          models: (
            .value.models
            | to_entries
            | map(.value + { id: .key })
            | map(. + { origin: {
                type: "discovered",
                discovered_at: (now | strftime("%Y-%m-%dT%H:%M:%SZ"))
              } })
          )
        }
      })
    | from_entries
  ' > "$SNAPSHOT.tmp.discovered" && mv "$SNAPSHOT.tmp.discovered" "$SNAPSHOT.discovered"

# Declared inventory (not from models.dev). Admin-owned backend models.
DECLARED="$REPO/pkgs/litellm-cli/data/models-seed.json"
if [ -f "$DECLARED" ]; then
  jq -s '.[0] * .[1]' "$SNAPSHOT.discovered" "$DECLARED" > "$SNAPSHOT.tmp" && mv "$SNAPSHOT.tmp" "$SNAPSHOT"
  rm -f "$SNAPSHOT.discovered"
else
  mv "$SNAPSHOT.discovered" "$SNAPSHOT"
fi

cd "$REPO"
git add pkgs/litellm-cli/data/models-dev.json

if git diff --cached --quiet; then
  echo "fetch-models: no changes to commit"
else
  if git commit -m "auto: update model inventory"; then
    echo "fetch-models: committed updated inventory"
  else
    echo "fetch-models: ERROR — git commit failed (check git identity / permissions)" >&2
    exit 1
  fi
fi
