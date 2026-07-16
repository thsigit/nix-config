# LiteLLM — Free Model Aggregator

## Overview

This module runs [LiteLLM](https://github.com/BerriAI/litellm) as a local AI proxy on port 4000, fronted by Caddy. The primary goal is to **aggregate as many free LLM providers and models as possible** under a single OpenAI-compatible API endpoint.

Models are sourced from [models.dev](https://models.dev) (auto-fetched daily) and hardcoded provider configs. Each provider offers a different set of free models with varying rate limits and restrictions.

## Why LiteLLM

LiteLLM provides a unified `v1/chat/completions` interface across dozens of providers — OpenAI-compatible, so any tool that speaks the OpenAI API (opencode, Continue, etc.) can use it without provider-specific adapters.

## Current Limitations

- **LiteLLM version is far behind upstream.** The nixpkgs package lags significantly. Some newer features and provider integrations may be missing.
- **Prisma / database backend does not work.** LiteLLM uses Prisma for its database layer, which is broken in the current nixpkgs build. The `database_url` in `settings.nix` is commented out and PostgreSQL runs idle (database + user are created by `postgres.nix` but unused). All state is in-memory.

## Provider Categories

Providers and their models are split into two categories:

### Free

Defined in `free-providers.nix`. These providers offer models with no cost and no special restrictions. The list of models per provider is auto-populated from `models-dev.json` — the daily snapshot from models.dev that only retains models where both input and output costs are zero.

Some providers have a manual whitelist (e.g. kenari is limited to 4 specific models).

**Current free providers:** aihubmix, cohere, nvidia, openrouter, kenari, zai

### Non-free

Defined in `nonfree-models.nix`. Despite the name, these models are also effectively free — but they come with restrictions such as stricter rate limits, require manual review, or have licensing terms that differ from the fully open providers. Models must be manually listed here (no auto-population from models.dev).

This category exists so we can **easily move models between free and non-free** as conditions change — a provider may tighten its free tier, or a previously restricted model may open up.

**Current non-free providers:** fireworks-ai (1 model)

### Manual

Defined in `manual-models.nix`. Models that don't come from models.dev or need special configuration (custom API base URLs, local endpoints). These are hardcoded entries.

**Current manual models:** gemini/gemini-2.5-flash-lite, ollama/llama3.2

## File Reference

| File | Purpose |
|---|---|
| `default.nix` | Entry point. Enables litellm, configures Caddy proxy, sets env vars. |
| `settings.nix` | LiteLLM general + litellm settings (master_key, json_logs, drop_params). |
| `models.nix` | Core model generation logic. Reads providers + models-dev.json, builds the model list, emits warnings for unconfigured providers. |
| `free-providers.nix` | Free provider definitions (API endpoints, env vars, optional model whitelist). |
| `nonfree-models.nix` | Non-free provider definitions (manually curated). |
| `manual-models.nix` | Hardcoded model entries that don't fit the provider framework. |
| `router.nix` | Router settings placeholder (currently empty). |
| `postgres.nix` | PostgreSQL setup — currently unused (Prisma broken). Kept for when database backend is re-enabled. |
| `fetch-models-service.nix` | Systemd timer + oneshot service for daily model snapshot updates. |
| `fetch-models.sh` | Shell script: fetches models.dev API, filters for free models, auto-commits to git. |
| `models-dev.json` | Auto-generated snapshot of models.dev (free models only, ~441KB). Updated daily by the fetch-models timer. |

## How Model Generation Works

The `models.nix` module generates the LiteLLM `model_list` at Nix build time:

1. `models-dev.json` is read and parsed as the source of truth for available providers and their free models.
2. For each provider in `free-providers.nix`, the system looks up the provider in `models-dev.json` to get model IDs and the API base URL.
3. Each model entry is expanded into a litellm config block with `model_name`, `model`, `api_base`, and `api_key` (from env var).
4. Non-free and manual models are appended directly.
5. A warning is emitted at build time listing any providers in `models.dev` that have free models but no configured API key — these are "missed" providers we could onboard.

The `litellm-missing` CLI tool (installed system-wide) shows the same info at runtime.

## Model Migration (free ↔ non-free)

Moving a model between categories:

- **free → non-free:** Remove from `free-providers.nix` (or its auto-populated model list) and add an entry to `nonfree-models.nix` with the appropriate env var.
- **non-free → free:** Remove from `nonfree-models.nix`. If the provider is already in `free-providers.nix` and the model is in models.dev, it will be picked up automatically. Otherwise, add it to the provider's manual model list.

The goal is that this is a **one-line change** in each direction.

## Daily Model Updates

The `fetch-models` systemd timer runs daily:

1. Fetches `https://models.dev/api.json`
2. Filters to only models where `cost.input == 0` and `cost.output == 0`
3. Writes the result to `models-dev.json`
4. Auto-commits to git with message `auto: update free models snapshot`

This keeps the model catalog current without manual intervention. New free models from supported providers appear automatically after the next rebuild.

---

_Auto-generated by opencode_
