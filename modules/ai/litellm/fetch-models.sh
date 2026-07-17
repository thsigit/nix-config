#!/usr/bin/env bash
set -euo pipefail

REPO="$(git rev-parse --show-toplevel 2>/dev/null)"
SNAPSHOT="$REPO/modules/ai/litellm/models-dev.json"

curl -sfL 'https://models.dev/api.json' |
  jq '
    with_entries(
      .value.models = (.value.models | with_entries(
        select(.value.cost.input == 0 and .value.cost.output == 0)
      ))
    ) | with_entries(select(.value.models | length > 0))
  ' > "$SNAPSHOT.tmp" && mv "$SNAPSHOT.tmp" "$SNAPSHOT"

cd "$REPO"
git add modules/ai/litellm/models-dev.json
git diff --cached --quiet || git commit -m "auto: update free models snapshot"
