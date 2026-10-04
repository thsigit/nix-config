# AGENTS.md — nix-lab

Instructions for coding agents working in this repo. Read this first.

## Architecture conventions (read before editing)

Before making changes to any Nix module in this repo, read and conform to:

- `/mnt/c/users/sigit/.config/opencode/application_architecture/principles.md` — general engineering principles (modularity, explicit interfaces, declarative-first, single source of truth, boring infrastructure, etc.).
- `/mnt/c/users/sigit/.config/opencode/application_architecture/nix.md` — Nix-specific guidelines (declarative over imperative, modules over monolith, options as public APIs, machine-specific config at the edge, etc.).

These define the "why" behind the structure of this flake. When the two conflict with a local rule in this file, the hard operating constraints below win; otherwise prefer the shared principles.

## Project

Personal NixOS flake for ONE physical machine -- a Toshiba Portege R30-C --
used in several roles. Every flake output builds that same machine; the
differences between roles are intentional and minimal.

| Flake output  | Profile       | Distinction                          |
|---------------|---------------|--------------------------------------|
| `server`      | `server`      | headless, base daemons, **no AI**    |
| `ai-gateway`  | `ai-gateway`  | headless + AI stack (litellm, webui) |
| `workstation` | `workstation` | desktop (XFCE) + AI stack            |
| `system`      | `system`      | base layer only (`../../system`)     |
| `failsafe`    | `failsafe`    | minimal recovery, independent        |

### Module layering

```nix
system/ + common/  ->  <profile>
```

- `system/` — the base OS layer: boot, kernel, locale, networking, users, ssh,
  firewall, power, bluetooth, shell, sudo. Leaves: `boot.nix`, `kernel.nix`,
  `locale.nix`, `networking.nix`, `users.nix`, `ssh.nix`, `sudo.nix`,
  `firewall.nix`, `power.nix`, `bluetooth.nix`, `shell.nix`,
  `grub-failsafe.nix`. (`default.nix` is a pure importer.)
- `common/` — long-running daemons. `default.nix` imports `ap`, `mail`,
  `media`, `monitoring`, `network`, `packages`, `security`, `storage`, `web`.
  It deliberately does **not** import `ai` — the AI stack graduated to
  `ai-common/`. (`common/db/` holds only `default.nix.old` and is imported by
  nothing.)
- `ai-common/` — the AI gateway stack, at the repo root since 2026-10-04 so a
  profile can list it explicitly instead of inheriting it through `common/`.

**Profiles do NOT import each other.** `ai-gateway` aggregates
`../../system + ../../common + ../../ai-common` itself; it does not import
`../server`. Profiles are alternatives you choose between, not layers to
inherit. `workstation` is the one deliberate exception — it imports
`../ai-gateway` so the desktop inherits the AI stack.

Note the name overlap: the `system/` directory and the `system` flake output
(profile) are unrelated to NixOS's `config.system.*` option namespace.

## Standing facts (do not ask each session)

- **Owner is currently on `#workstation`** → always target/rebuild the
  `workstation` profile (flake: `.#workstation`) by default unless told otherwise.
- `#server` and `#workstation` are the SAME hardware. `#server` is headless and
  carries NO AI stack; `#workstation` is the desktop and DOES carry it (it
  imports `../ai-gateway`). That divergence is deliberate: the AI stack was
  graduated out of `common/` into `ai-common/` precisely so `server` could shed
  it. Do not re-add `ai-common` to `server`'s import list.
- The live system currently runs `#server`. The owner switches to `#workstation`
  for daily desktop use.
- One repo in `/srv/repo/nix-lab`: branch `dev` = active development (local-only), branch `main` = public release (the deployed end product, the only branch pushed to GitHub). See `WORKFLOW.md`. GitHub's nix-config is the **rolling release** (`main`).
  - **Publish (dev → GitHub):** `git checkout main && git merge dev && git push origin main && git checkout dev`

## Operating constraints (hard rules — do not "fix" them away)

### NEVER run `sudo nixos-rebuild` (switch/build/boot/test)
- Passwordless sudo is allowed for everything EXCEPT `nixos-rebuild`.
  `system/sudo.nix` requires a password for
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
  into the real runtime (providers.json under `/srv/appdata/litellm`, ephemeral
  files under `/run/litellm-cli`).
- For verification, use a temp dir with the raw
  `/srv/repo/litellm-cli/bin/*` scripts and explicit `LITELLM_*` env vars.

## Key paths / sources of truth

- `settings/` — canonical `user`, `ai`, `directories` (incl. `appdata`).
- `flake.nix` — defines which machine + profile builds what.
- `ai-common/` — AI gateway stack; leaf modules are self-contained and
  always-on when imported (mrtg-style standard); the directory `default.nix`
  is a pure importer. The LiteLLM stack is grouped under `ai-common/litellm/`
  (its own `default.nix` importer + leaf files); other leaves stay flat in
  `ai-common/`. No per-leaf `enable` toggles.
  - `ai-common/litellm/litellm.nix` — LiteLLM native systemd service (port 4000), DynamicUser.
    Consumes static config.yaml from /srv/appdata/litellm. Always-on.
  - `ai-common/litellm/litellm-cli.nix` — wires the external `services.litellm-cli` module
    (config layer + admin CLI from the litellm-cli repo).
  - `llama-cpp.nix`, `open-webui.nix`, `opencode.nix`, `whisper.nix` — the
    other AI services. (A `bitrouter.nix` and a `vane-podman.nix` were
    documented here historically; neither exists in the tree any more.)
- `common/network/` — network services (tailscale, zerotier, dnsmasq).
  dnsmasq is imported directly by `common/network/default.nix` so LAN DNS
  survives independently of the AP bundle.
- `common/ap/` — the access-point bundle (hostapd + freeradius), gated by a
  single `services.ap.enable` flag. This option is *declared* in
  `common/ap/default.nix`, so anything setting `services.ap.enable` must have
  `common/ap` in its import closure — `profiles/workstation` gets it via
  `common/`. openNDS used to live here and was dropped 2026-09-03 (its nft
  client-tracking never registered in this nft/iptables hybrid env and its
  reject tables blocked all AP internet).
- `/srv/repo/litellm-cli/` (separate git repo, NOT part of nix-lab) — the
  `services.litellm-cli` module: inventory, policy, renderer, admin CLIs.
  Consumed as flake input `litellm-cli` = `path:/srv/repo/litellm-cli`
  (`flake = false`), passed to modules via specialArgs `litellmCli`.
  DO NOT git-add it into this repo. Its data contract:
  `/srv/appdata/litellm/config.yaml` (persistent, admin-owned; static model_list
  seeded from `ai-common/litellm/config.yaml` on first boot, then edited by
  `litellm-cli config add/remove` -- never re-rendered by rebuild) ->
  `/run/litellm-cli/health.json` (ephemeral, rebuilt each boot).
- `secrets/` + `.sops.yaml` — sops secrets. Files actually present:
  `providers.env`, `radius.yaml` (radius-secret + radius-users), `infra.yaml`.
  `litellm.env` and `opennds.yaml` are documented historically and no longer
  exist (openNDS was dropped 2026-09-03). All secrets are read at runtime from
  sops, never baked into the store. Declared in `common/security/sops.nix`.

## SSH access

- Authorized keys are declared in `system/ssh.nix`, so `server`, `ai-gateway`
  and `workstation` all get them. `profiles/failsafe` does NOT import
  `../../system` — by design — so it keeps its own inline copy; that duplication
  is what keeps recovery working when this tree is broken.
- These keys are **live**, not decorative. nixpkgs renders
  `users.users.<name>.openssh.authorizedKeys` to
  `/etc/ssh/authorized_keys.d/<user>` via `authKeysFiles` in
  `nixos/modules/services/networking/ssh/sshd.nix`, and sshd reads that path.
  All three keys (`vantage`, `FedoraWSL`, `V2333`) were dead config from
  2026-08-06 (`628336f`) until they were uncommented on 2026-10-04.
- A hand-placed `~/.ssh/authorized_keys` (2 keys, missing `V2333`) still exists
  and, on `#server` before that rebuild, was the thing actually granting access.
  Do not delete it until after one successful `switch` to a key-bearing profile,
  verified by logging in from a **second terminal** with the manual file moved
  aside. Keeping a tested escape hatch is the whole point.
- The hardening block (`services.openssh.settings` with
  `PasswordAuthentication = false`, `PermitRootLogin = "no"`) is commented out in
  `system/ssh.nix` and enabled only in `ai-gateway`. Password auth is therefore
  still accepted on `server` and `workstation`. Changing that is a separate
  decision — verify key-only login before enabling it anywhere else.

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
- **Cross-module ordering** (e.g. "litellm waits for litellm-render") belongs
  in the dependent module via `systemd.services.<unit>.after`, not in the
  dependency's module reading a custom enable option.

## LiteLLM runtime notes

- **Runs WITHOUT PostgreSQL (no-DB mode).** The nixpkgs litellm package has a broken Prisma client generation (upstream issue). LiteLLM runs in pure API proxy mode with no spend tracking or user/key management via UI.
- **Cert:** Caddy serves a valid *.home.arpa cert from the Homelab Internal CA. If a
  browser shows a cert error, install that CA in the client trust store -- it is a
  client-side trust issue, not a server config problem.
- **Config is owned by litellm-cli** and lives at /srv/appdata/litellm/config.yaml (seeded from ai-common/litellm/config.yaml on first boot, then edited manually -- never re-rendered by rebuild).
## Access-point gotchas

- The AP bundle is `common/ap/` — hostapd + freeradius, an **open** AP with no
  captive portal. Gated by one flag: `services.ap.enable`, which is *declared*
  in `common/ap/default.nix`. Anything that sets it must have `common/ap` in its
  import closure; profiles get it transitively via `common/`.
- **openNDS was removed 2026-09-03** (`7961f47` and after). Its nft
  client-tracking (`ndsOUT` mangle) never registered clients in this
  nft/iptables hybrid environment, and its reject tables blocked all AP
  internet. If you are reading older notes about `ndscfg`/`ndsctl`, foreground
  `opennds -f`, or the `opennds-pre`/`opennds-post` nft chains, they are
  obsolete — none of that code exists in the tree any more.
- FreeRADIUS certificate generation moved to a **oneshot** service
  (`7961f47`, fixing a `no-usable-init` boot failure). Do not move it back into
  the main unit.
- RADIUS secrets (`radius-secret`, `radius-users`) come from sops at activation
  and are never hardcoded. Never flush the shared `nixos-nat-*` chains to debug
  routing — that destroys other modules' rules.
