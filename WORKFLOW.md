# nix-lab branch workflow

*State snapshot updated: 2026-11-09.*

## The question

> "What's the state of nix-config/nix-lab and how to work on it?"

## The answer

### Current state

**`/srv/repo/nix-lab` — the ONE working repo**
- On branch **`dev`**, HEAD `53cf343` (`update opencode to latest`, 2026-10-22)
- Working tree has uncommitted local changes: `flake.lock`, `flake.nix`,
  `secrets/providers.env` (treat as in-progress; review before committing)
- Remotes: `origin` = `git@github.com:thsigit/nix-config.git` (SSH)
- Local branches: `dev` (development, **local-only**) and `main` (release)
- `main` is at `8f400da` (`Add debianWSL SSH authorized key`, 2026-10-20),
  tracking `origin/main`; `dev` is 1 commit ahead of `main` (plus the local
  uncommitted changes above)
- `/srv/repo/nix-lab-snapshot` was removed (no longer needed)

**GitHub (`thsigit/nix-config`)**
- Only **`main`** is pushed (rolling release). `dev` stays local.
- tag `pre-ap-gateway` points at the old snapshot head.

### How to work in the future

All work happens in `nix-lab` only. One pushed branch:

```
nix-lab (working copy)
 ├─ dev   → daily development branch   (you work here, LOCAL ONLY)
 └─ main  → public release snapshot    (the deployed end product, pushed to GitHub)
```

**Everyday dev** — just work on `dev`:

```
cd /srv/repo/nix-lab        # already on dev
... edit, commit ...
```

**When you want a release** (make it public):

```
git checkout main
git merge dev               # fast-forward — dev is an ancestor of main
git push origin main        # over SSH, no token; the ONLY branch pushed
git checkout dev            # back to dev
```

That is the entire release flow — a fast-forward merge + push. No `git rm -r`,
no copy, no script. The public "end product" (the GitHub repo) is simply the
`main` branch of this one repo; `dev` is your private working branch.

To deploy the release: `git checkout main && nixos-rebuild ...`, then
`git checkout dev`.

## Why we changed

Previously `nix-lab` (development) and `nix-config` (public release) were two
repos with **unrelated git histories** and different layouts. Every release was
a fragile manual `git rm -r` + copy that erased nix-config's history continuity.

We migrated to **one repo**: `dev` for development and `main` for the public
release, where `main` is a descendant of `dev` (a merge commit unifying both
histories). This makes every release a normal fast-forward merge. `dev` is
kept **local-only** so GitHub shows a single clean `main` branch. History is
preserved; nothing is erased.
