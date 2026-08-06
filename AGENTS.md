# AGENTS.md — nix-lab

Instructions for coding agents working in this repo. Read this first.

## Project

Personal NixOS flake for two hosts that are the **same physical machine**:
Toshiba Portege R30-C. Differences are intentional and minimal:

| Host         | Profile      | Distinction            |
|--------------|--------------|------------------------|
| `homelab`    | `homelab`    | headless (server)      |
| `workstation`| `workstation`| desktop (XFCE + SDDM)  |

Flake outputs: `homelab` = `portege-r30c` machine + `homelab` profile;
`workstation` = `portege-r30c` machine + `workstation` profile.
Also `failsafe` = minimal recovery profile.

## Standing facts (do not ask each session)

- **Owner is currently on `#workstation`** → always target/rebuild the
  `workstation` profile (flake: `.#workstation`) by default unless told otherwise.
- `#homelab` and `#workstation` are the SAME hardware. The only divergence today
  is headless vs desktop GUI. **Keep it that way** — do not add meaningful
  differences between the two profiles beyond that.
- `/srv/repo/nix-lab` is the **active** repo (branch `main`). `/srv/repo/nix-config` is the **stable** repo. GitHub's nix-config is the **rolling release**.

## Operating constraints (hard rules — do not "fix" them away)

### NEVER run `sudo nixos-rebuild` (switch/build/boot/test)
- Passwordless sudo is allowed for everything EXCEPT `nixos-rebuild`.
  `modules/security/sudo.nix` requires a password for
  `/run/current-system/sw/bin/nixos-rebuild`.
- This rule was wrongly dropped in `3a474af` (to unblock an activation script)
  and restored in `4a7b55e`. Do not remove it again.
- If a change needs a rebuild, commit it and tell the owner to run
  `sudo nixos-rebuild switch` themselves. This agent must not run it.

### No `wall` broadcasts
- `litellm-podman/config.nix`'s render-restart script notifies via `logger` only.
  `wall` was removed (it freezes terminals). Do not reintroduce `wall`.

### Do not experiment against the real runtime state dir
- The wrapped `result/sw/bin/*` CLIs hardcode
  `LITELLM_STATE_DIR=/srv/appdata/litellm` and write into the real runtime.
- For verification, use a temp dir with the raw
  `pkgs/litellm-cli/bin/*` scripts and explicit `LITELLM_*` env vars.

## Key paths / sources of truth

- `settings/` — canonical `user`, `ai`, `directories` (incl. `appdata`).
- `flake.nix` — defines which machine + profile builds what.
- `modules/ai/` — AI gateway stack, one self-contained dir per service:
  - `litellm-podman/` — LiteLLM gateway: `podman.nix` (active container, port 4000)
    + `config.nix` (inventory/policy + renderer, the core of the project).
    Enabled via `ai.podmanLitellm.enable` + `ai.litellmConfig.enable`.
  - `bitrouter/` — BitRouter LLM gateway (container mode, port 4356).
    Enabled via `services.bitrouter.enable`; mode `native`/`container`.
  - `litellm/` — disabled reference systemd-native module (do not enable).
  - `ollama.nix`, `opencode.nix`, `podman-vane.nix` — other AI services.
- `modules/network/` — network services. Access-point bundle lives in
  `modules/network/ap/` (hostapd, router/NAT, freeradius, opennds), toggled by a
  single `services.ap.enable` flag. dnsmasq is imported directly by
  `modules/network/default.nix` (LAN DNS must survive the AP bundle being off).
- `pkgs/litellm-cli/` — inventory (`models.json`), policy (`providers.json`),
  renderer (`litellm-render`), and admin CLIs.
- `pkgs/opennds/` — openNDS 11.0.0 package (unwrapped binaries in `libexec`,
  PATH wrappers in `bin`).
- `secrets/` + `.sops.yaml` — sops secrets: `litellm.env`, `providers.env`,
  `opennds.yaml` (faskey), `radius.yaml` (radius-secret, radius-users).
  All AP secrets are read at runtime from sops, never baked into the store.
- `modules/security/sops.nix` — declares the sops secrets.

## LiteLLM runtime notes

- **Runs in no-DB mode.** LiteLLM v1.92.0 requires **PostgreSQL** for DB features;
  `sqlite://` is rejected at startup and crash-loops the container. So we do NOT set
  `database_url`. API proxying works with the master key as a Bearer token (what
  opencode/Continue use). The UI user/key management needs Postgres if ever wanted.
- **Cert:** Caddy serves a valid `*.home.arpa` cert from the Homelab Internal CA. If a
  browser shows a cert error, install that CA in the client trust store — it is a
  client-side trust issue, not a server config problem.
- **v1.92.0 entrypoint reads `/app/config.yaml`** (ignores `--config`/cmd). The module
  mounts the rendered config there. `:main` nightly is broken (hangs on large configs) —
  do not revert to it.

## Access-point (openNDS) gotchas

- openNDS runs **foreground** (`opennds -f`, `Type = exec`) so systemd tracks it.
  Do not revert to `-b`/forking.
- faskey + RADIUS secrets come from sops at runtime/activation; never hardcode them.
- Do NOT symlink into `/usr/local/bin` — NixOS has no such path and it aborts the
  activation script. ndscfg/ndsctl are already on PATH via the package.
- NAT uses dedicated `opennds-pre`/`opennds-post` chains; never flush the shared
  `nixos-nat-*` chains (that destroys other modules' rules).
- openNDS needs dnsmasq as a hard runtime dependency (reads its leases file).
