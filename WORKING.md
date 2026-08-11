# WORKING — nix-lab operating notes

## 1. Standing facts
- Two hosts, same hardware (Portege R30-C). Profiles: **homelab** (headless) and **workstation** (+XFCE). The owner is currently on `#workstation` and rebuilds with `.#workstation` by default.
- `profiles/desktop` is a placeholder for a future machine `machines/vantage-v14g4` plus a Linux desktop (not defined yet).
- **Hard rule:** NEVER run `sudo nixos-rebuild`. Commit changes and let the owner rebuild.
- **No `wall` broadcasts** – only `logger` is used for notifications.
- **No-DB mode** for LiteLLM – SQLite is rejected; the container runs without a database. The Master-key Bearer token is all that is needed for proxy operation.
- **TLS:** Caddy serves a wildcard `*.home.arpa` cert from the homelab internal CA. If a client reports a cert error, install the CA on that client – it is not a server issue.

## 2. Architecture (high-level diagram)
```
repo layout:
  common/          # reusable NixOS modules
    ai/            # LiteLLM gateway (wrapper + podman runtime)
    network/       # Wi-Fi gateway (hostapd, dnsmasq, openNDS, firewall)
  profiles/        # role compositions (homelab, workstation, desktop)
  pkgs/            # custom packages (bitrouter, litellm-cli, opennds)
  machines/        # per-machine hardware configs
  secrets/         # SOPS-encrypted env files
```

### Internet gateway (Wi-Fi)
```
client → hostapd (wlp2s0) → dnsmasq (DHCP/DNS) → nftables redirect → openNDS (captive portal)
    ↳ splash page → click-continue → openNDS marks client (0x00030000)
    ↳ nftables ndsNET chain allows marked traffic → NAT → WAN (enp0s31f6)
```

### AI gateway (LiteLLM)
```
models.json (inventory)   providers.json (policy)   → litellm-render → config.yaml
    │                         │                         │
    └───► /srv/appdata/litellm/models.json   └───► /srv/appdata/litellm/providers.json

config.yaml is mounted read-only into the `podman-litellm` container (port 4000) and fronted by Caddy.
Changes to `models.json` or `providers.json` trigger a systemd path unit that re-renders `config.yaml` and auto-restarts the container.
```

## 3. Operating notes – gotchas (verified)
### openNDS (`common/network/opennds.nix`)
- **PATH** for the service must include `wget` and the `opennds` package; otherwise the MHD health-check loop constantly restarts the daemon.
- **Theme symlink:** `theme_click-to-continue.sh` → `theme_click-to-continue-basic.sh` (handled in the setup script).
- **`ndsctl` / `ndscfg`** are symlinked into `/usr/local/bin` by the setup script.
- **NAT mark fix:** use `meta mark set mark or 0x1` (bitwise OR) instead of overwriting the openNDS auth mark (`0x00030000`).
- **`gatewayfqdn 'disable'`** is ignored by openNDS v11; simply omit the option to default to the IP address.
- **`nft` usage:** reference the full path `${pkgs.nftables}/bin/nft` in `extraCommands` – the firewall-start script does not inherit `nft`.
- **`&` in nft rules:** wrap the rule block in a single-quoted heredoc (`<<'HEREDOC'`) to prevent the shell from interpreting `&`.

### LiteLLM (`common/ai/podman-litellm.nix` & `litellm-config.nix`)
- **Image pinned:** `ghcr.io/berriai/litellm:v1.92.0`. The `:main` nightly hangs the event loop with large model lists.
- **Mount point:** container expects `/app/config.yaml`. The module passes `--config /app/config.yaml` explicitly.
- **No database:** `sqlite://` is unsupported and crashes the container. Run in no-DB mode; the UI’s user management is unavailable unless a PostgreSQL instance is added.
- **`api_base` verbatim:** providers must include the full endpoint path. Example: Cohere needs `https://api.cohere.com/v2/chat`; OpenAI-compatible providers use the `/v1` root.
- **`providers.json`** is runtime-only; it is seeded from `data/providers-seed.json` only if the file does not already exist. Editing this file via the CLI rewrites it without a rebuild and triggers an auto-restart.
- **`models.json`** is always merged on rebuild; manual-origin entries (added via `litellm-add-provider --models`) survive rebuilds.
- **Health endpoint:** `/health` returns `000` in no-DB mode; use `/v1/models` or `litellm-doctor` for health checks.

## 4. Active task
- See `sessions/2026-08-01-gateway-service-refactor.md` for the current refactor plan: each gateway (AI and Internet) will become a self-contained directory under `common/gateways/...` and be enable-able from a profile with a single import line or `services.<name>.enable = true`.

## 5. Decisions log (atomic entries)
- **2026-07-19** – Keep all three LiteLLM modules (`litellm` reference, `podman-litellm` runtime, `litellm-wrapper` core). The wrapper is the primary operational layer.
- **2026-07-19** – LiteLLM runs in no-DB mode; SQLite is unsupported, PostgreSQL is required for UI features.
- **2026-07-26** – openNDS initial build completed; MHD health-check loop fixed, NAT mark fix applied, theme symlink added.
- **2026-07-26** – LiteLLM container pinned to `v1.92.0` after `:main` nightly caused hangs.
- **2026-08-01** – Begin gateway-service refactor to self-contained directories with single-line enable flags.
