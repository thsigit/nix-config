# AGENTS.md — nix-lab

Instructions for coding agents working in this repo. Read this first.

## Project

Personal NixOS flake for two hosts that are the **same physical machine**:
Toshiba Portege R30-C. Differences are intentional and minimal:

| Host         | Profile      | Distinction            |
|--------------|--------------|------------------------|
| `server`     | `server`     | headless (server)      |
| `workstation`| `workstation`| desktop (XFCE + SDDM)  |

Flake outputs: `server` = `portege-r30c` machine + `server` profile;
`workstation` = `portege-r30c` machine + `workstation` profile.
Also `failsafe` = minimal recovery profile.

## Standing facts (do not ask each session)

- **Owner is currently on `#workstation`** → always target/rebuild the
  `workstation` profile (flake: `.#workstation`) by default unless told otherwise.
- `#server` and `#workstation` are the SAME hardware. The only divergence today
  is headless vs desktop GUI. **Keep it that way** — do not add meaningful
  differences between the two profiles beyond that.
- `/srv/repo/nix-lab` is the **active** repo (branch `main`). `/srv/repo/nix-config` is the **stable** repo. GitHub's nix-config is the **rolling release**.

## Operating constraints (hard rules — do not "fix" them away)

### NEVER run `sudo nixos-rebuild` (switch/build/boot/test)
- Passwordless sudo is allowed for everything EXCEPT `nixos-rebuild`.
  `common/security/sudo.nix` requires a password for
  `/run/current-system/sw/bin/nixos-rebuild`.
- This rule was wrongly dropped in `3a474af` (to unblock an activation script)
  and restored in `4a7b55e`. Do not remove it again.
- If a change needs a rebuild, commit it and tell the owner to run
  `sudo nixos-rebuild switch --flake /srv/repo/nix-lab#server` (or `#workstation`)
  themselves. This agent must not run it.

### On a failed build, revert ONLY the broken module — never roll back nixpkgs
- When a `nixos-rebuild switch` fails (e.g. an activation script errors),
  fix the specific offending file. Do NOT `git reset --hard` to a commit that
  also reverts `flake.lock`/nixpkgs — that discards the already-downloaded and
  built closure and forces a full ~10+ GiB re-download on the next switch.
- Nix store paths are content-addressed: a different nixpkgs commit
  (`flake.lock` rev) yields different derivation hashes, so the next switch
  re-fetches from `cache.nixos.org` even if an "earlier" rev was already built.
- Correct fix pattern: restore only the broken files to their pre-change
  content (e.g. `git checkout <parent> -- common/db/default.nix`) while keeping
  `flake.lock` pinned to the nixpkgs rev already present in the store.
- Recorded after the 2026-08-20 incident: a `git reset --hard db4e196` reverted
  the `0dd31db` nixpkgs bump that had just been built, then re-bumping to
  `b18a4b9` re-downloaded the whole closure. Lesson: pin to the built rev,
  revert surgically.

### No `wall` broadcasts
- Config-change restart notifies via `logger` only.
  `wall` was removed (it freezes terminals). Do not reintroduce `wall`.

### Do not experiment against the real runtime state dir
- The wrapped `result/sw/bin/*` CLIs hardcode the deployment env and write
  into the real runtime (gateway.json under `/srv/appdata/litellm`, ephemeral
  files under `/run/litellm-cli`).
- For verification, use a temp dir with the raw
  `/srv/repo/litellm-cli/bin/*` scripts and explicit `LITELLM_*` env vars.

## Key paths / sources of truth

- `settings/` — canonical `user`, `ai`, `directories` (incl. `appdata`).
- `flake.nix` — defines which machine + profile builds what.
- `common/ai/` — AI gateway stack; leaf modules are self-contained and
  always-on when imported (mrtg-style standard); the directory `default.nix`
  is a pure importer. The LiteLLM stack is grouped under `common/ai/litellm/`
  (its own `default.nix` importer + leaf files); other leaves stay flat in
  `common/ai/`. No per-leaf `enable` toggles.
  - `litellm.nix` — LiteLLM native systemd service (port 4000), DynamicUser.
    Consumes litellm-cli rendered config.yaml. Always-on.
  - `litellm-cli.nix` — wires the external `services.litellm-cli` module
    (config layer + admin CLI from the litellm-cli repo).
  - `bitrouter.nix` — BitRouter LLM gateway, `services.bitrouter` (bespoke
    module, self-enabled via `mkDefault true`), mode `native`/`container`.
  - `llama-cpp.nix`, `opencode.nix`, `vane-podman.nix` — other AI services.
- `common/network/` — network services. Access-point bundle lives in
  `common/network/ap/` (hostapd, router/NAT, freeradius, opennds), toggled by a
  single `services.ap.enable` flag. dnsmasq is imported directly by
  `common/network/default.nix` (LAN DNS must survive the AP bundle being off).
- `/srv/repo/litellm-cli/` (separate git repo, NOT part of nix-lab) — the
  `services.litellm-cli` module: inventory, policy, renderer, admin CLIs.
  Consumed as flake input `litellm-cli` = `path:/srv/repo/litellm-cli`
  (`flake = false`), passed to modules via specialArgs `litellmCli`.
  DO NOT git-add it into this repo. Its data contract:
  `/srv/appdata/litellm/gateway.json` (persistent, admin-owned; holds provider
  config + routing + MANUAL models via `providers add --models`) →
  `/run/litellm-cli/{models.json,config.yaml,health.json}` (ephemeral, rebuilt
  each boot). Never put hand-added models in `models.json` — it's tmpfs.
- `pkgs/opennds/` — openNDS 11.0.0 package (unwrapped binaries in `libexec`,
  PATH wrappers in `bin`).
- `secrets/` + `.sops.yaml` — sops secrets: `litellm.env`, `providers.env`,
  `opennds.yaml` (faskey), `radius.yaml` (radius-secret, radius-users).
  All AP secrets are read at runtime from sops, never baked into the store.
- `common/security/sops.nix` — declares the sops secrets.

## Module conventions (coding standard)

- **Prefer upstream open attrsets over custom `options.services.<x>` wrappers.**
  Write service units directly into the already-declared, open namespaces
  (`systemd.services.*`, `systemd.timers.*`,
  `services.caddy.*`,
  `environment.systemPackages`) instead of inventing a new
  `options.services.<x>` option tree just to wrap a binary. e.g. a leaf that
  runs a binary should define `systemd.services.foo`, not `options.services.foo`.
- **Leaf modules are self-contained and always-on when imported.** Each
  `common/<area>/` directory has a `default.nix` that is a pure importer
  (`imports` only). The leaf `.nix` files own their defaults and enable
  themselves; there are no per-leaf `enable` toggles at the directory level.
- **Bespoke service modules are the exception.** If a module defines a genuinely
  new service (e.g. `services.bitrouter`), its intrinsic `options` stay in that
  module, but it self-enables with `lib.mkDefault true` so importing turns it on.
  A profile can still override with a plain `services.bitrouter.enable = false`.
- **Cross-module ordering** (e.g. "gateway waits for DB password sync") belongs
  in the dependent module via `systemd.services.<unit>.after`, not in the
  dependency's module reading a custom enable option.

## LiteLLM runtime notes

- **Runs WITH PostgreSQL.** LiteLLM requires **PostgreSQL** for DB features;
  `sqlite://` is rejected at startup. `common/db` generates
  `${appdata}/litellm/database.env` (`DATABASE_URL=postgresql://…`), which
  `litellm.nix` reads as an `environmentFile`. The native service orders after
  `litellm-db-password.service` so the role password is synced first. API proxying
  + UI user/key management both work.
- **Cert:** Caddy serves a valid `*.home.arpa` cert from the Homelab Internal CA. If a
  browser shows a cert error, install that CA in the client trust store — it is a
  client-side trust issue, not a server config problem.
- **Config is owned by litellm-cli** and rendered to `/run/litellm-cli/config.yaml`.
  The native service reads it via `--config` flag. `:main` nightly is broken
  (hangs on large configs) — do not revert to it.

## Access-point (openNDS) gotchas

- openNDS runs **foreground** (`opennds -f`, `Type = exec`) so systemd tracks it.
  Do not revert to `-b`/forking.
- faskey + RADIUS secrets come from sops at runtime/activation; never hardcode them.
- Do NOT symlink into `/usr/local/bin` — NixOS has no such path and it aborts the
  activation script. ndscfg/ndsctl are already on PATH via the package.
- NAT uses dedicated `opennds-pre`/`opennds-post` chains; never flush the shared
  `nixos-nat-*` chains (that destroys other modules' rules).
- openNDS needs dnsmasq as a hard runtime dependency (reads its leases file).
