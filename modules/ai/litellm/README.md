# LiteLLM — AI Gateway Controller

## Overview

This module runs [LiteLLM](https://github.com/BerriAI/litellm) as a local AI proxy on port 4000, fronted by Caddy. It acts as a **controller** — managing the full lifecycle from provider discovery to runtime config generation.

Models are sourced from [models.dev](https://models.dev) (auto-fetched daily) and hardcoded provider configs. Each provider offers different models with varying rate limits and restrictions.

## Architecture

The system follows a layered controller pattern:

```
Discovery → Inventory → Policy → Renderer → Runtime
```

| Layer | Files | Purpose |
|---|---|---|
| **Discovery** | `fetch-models-service.nix`, `models-dev.json` | Source providers from models.dev |
| **Inventory** | `models.nix`, `models.json` | Internal database of all models |
| **Policy** | `providers-enabled.json`, `health.nix`, `router.nix` | What should be exposed |
| **Renderer** | `renderer.nix`, `config.yaml` | Convert policy → LiteLLM config |
| **Runtime** | LiteLLM service | Serves requests |

### Data Flow

```
models.dev API
  ↓ (daily fetch)
models-dev.json
  ↓ (Nix build: models.nix)
models.json
  ↓ (runtime filter: providers-enabled.json)
renderer.nix
  ↓ (ExecStartPre)
config.yaml
  ↓ (LiteLLM service)
OpenAI-compatible API
```

## Why LiteLLM

LiteLLM provides a unified `v1/chat/completions` interface across dozens of providers — OpenAI-compatible, so any tool that speaks the OpenAI API (opencode, Continue, etc.) can use it without provider-specific adapters.

## Current Limitations

- **LiteLLM version is far behind upstream.** The nixpkgs package lags significantly. Some newer features and provider integrations may be missing.
- **Prisma / database backend does not work.** LiteLLM uses Prisma for its database layer, which is broken in the current nixpkgs build. The `database_url` in `settings.nix` is commented out and PostgreSQL runs idle (database + user are created by `postgres.nix` but unused). All state is in-memory.

## Provider Categories

Providers and their models are split into categories:

### Open

Defined in `providers-open.nix`. These providers offer models with no cost and no special restrictions. The list of models per provider is auto-populated from `models-dev.json` — the daily snapshot from models.dev that only retains models where both input and output costs are zero.

Some providers have a manual whitelist (e.g. kenari is limited to 4 specific models).

**Current open providers:** aihubmix, cohere, nvidia, openrouter, kenari, zai

### Restricted

Defined in `providers-restricted.nix`. These models are also effectively free — but they come with restrictions such as stricter rate limits, require manual review, or have licensing terms that differ from the fully open providers. Models must be manually listed here (no auto-population from models.dev).

This category exists so we can **easily move models between open and restricted** as conditions change — a provider may tighten its free tier, or a previously restricted model may open up.

**Current restricted providers:** fireworks-ai (1 model)

### Manual

Defined in `providers-manual.nix`. Models that don't come from models.dev or need special configuration (custom API base URLs, local endpoints). These are hardcoded entries.

**Current manual models:** gemini/gemini-2.5-flash-lite, ollama/llama3.2

## Runtime State

Runtime files live in `/srv/appdata/litellm/`:

| File | Purpose |
|---|---|
| `models.json` | Full model inventory (written at build time) |
| `providers-enabled.json` | Which providers are enabled (runtime config, survives rebuilds) |
| `config.yaml` | Generated LiteLLM config (written by renderer before each start) |
| `health.json` | Provider health state (written by doctor) |

### State Management

- `models.json` — updated on every rebuild via activation script
- `providers-enabled.json` — created only if missing (preserves manual changes)
- `config.yaml` — regenerated before each service start
- `health.json` — updated by hourly health check

## CLI Tools

### Provider Management

```bash
# List all providers and their status
litellm-providers

# Disable a provider
sudo litellm-disable-provider kenari

# Enable a provider
sudo litellm-enable-provider kenari
```

After changing provider status, restart the service:

```bash
sudo systemctl restart litellm
```

### Health Monitoring

```bash
# Check health of all enabled providers (requires API keys in env)
sudo litellm-doctor

# View cached health status (no API calls)
litellm-status
```

Health checks run hourly via systemd timer.

## File Reference

| File | Purpose |
|---|---|
| `default.nix` | Composition entry point. Imports all layers, configures Caddy proxy. |
| `state.nix` | Centralizes all runtime file paths (dataDir, models.json, etc.) |
| `settings.nix` | LiteLLM general + litellm settings (master_key, json_logs, drop_params). |
| `renderer.nix` | Renders config.yaml from models.json + providers-enabled.json. Owns ExecStart/Pre, ReadWritePaths. |
| `models.nix` | Generates model inventory. Writes models.json + providers-enabled.json defaults. |
| `providers-open.nix` | Open provider definitions (API endpoints, env vars, optional model whitelist). |
| `providers-restricted.nix` | Restricted provider definitions (manually curated). |
| `providers-manual.nix` | Hardcoded model entries that don't fit the provider framework. |
| `health.nix` | Provider health monitoring, CLI tools, systemd timer. |
| `router.nix` | Router settings placeholder (future: policy layer). |
| `postgres.nix` | PostgreSQL setup — currently unused (Prisma broken). Kept for when database backend is re-enabled. |
| `fetch-models-service.nix` | Systemd timer + oneshot service for daily model snapshot updates. |
| `fetch-models.sh` | Shell script: fetches models.dev API, filters for free models, auto-commits to git. |
| `models-dev.json` | Auto-generated snapshot of models.dev (free models only, ~441KB). Updated daily by the fetch-models timer. |

## How Model Generation Works

The `models.nix` module generates the model inventory at Nix build time:

1. `models-dev.json` is read and parsed as the source of truth for available providers and their free models.
2. For each provider in `providers-open.nix`, the system looks up the provider in `models-dev.json` to get model IDs and the API base URL.
3. Each model entry is expanded into a litellm config block with `model_name` (includes provider key), `model` (with API prefix), `api_base`, and `api_key`.
4. Restricted and manual models are appended directly.
5. `models.json` is written to `/srv/appdata/litellm/` via activation script.
6. A warning is emitted at build time listing any providers in `models.dev` that have free models but no configured API key.

## How Rendering Works

The `renderer.nix` module converts policy to runtime config:

1. On service start, `ExecStartPre` runs the `litellm-generate-config` script.
2. Script reads `models.json` (full inventory) and `providers-enabled.json` (policy).
3. Filters models to only enabled providers.
4. Generates `config.yaml` for LiteLLM.
5. Service starts with `--config /srv/appdata/litellm/config.yaml`.

## Provider Migration (open ↔ restricted)

Moving a model between categories:

- **open → restricted:** Remove from `providers-open.nix` (or its auto-populated model list) and add an entry to `providers-restricted.nix` with the appropriate env var.
- **restricted → open:** Remove from `providers-restricted.nix`. If the provider is already in `providers-open.nix` and the model is in models.dev, it will be picked up automatically.

The goal is that this is a **one-line change** in each direction.

## Daily Model Updates

The `fetch-models` systemd timer runs daily:

1. Fetches `https://models.dev/api.json`
2. Filters to only models where `cost.input == 0` and `cost.output == 0`
3. Writes the result to `models-dev.json`
4. Auto-commits to git with message `auto: update free models snapshot`

This keeps the model catalog current without manual intervention. New free models from supported providers appear automatically after the next rebuild.
