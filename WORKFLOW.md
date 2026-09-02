# nix-lab → nix-config workflow (2026-09-03)

## The question

> "What's the new state of nix-config/nix-lab and how to work on them in the
> future?"

## The answer

### Current state

**`/srv/repo/nix-lab` — the ONE working repo**
- On branch **`dev`**, HEAD `5f84708` (clean)
- Remotes: `origin` = `git@github.com:thsigit/nix-config.git` (SSH)
- Branches in this repo: `dev` (development) and `main` (release)
- No `release.sh`, no `stable` remote

**`/srv/repo/nix-lab-snapshot` — an occasional snapshot**
- Still on disk, clean at `eba912a`
- Nothing points to it anymore; its history is preserved in `main`. It exists
  purely as a backup snapshot of the old release method.

**GitHub (`thsigit/nix-config`)**
- `dev` = `5f84708`
- `main` = `dae8841` (dev history + old nix-config history merged)
- tag `pre-ap-gateway` = `5f84708`

### How to work in the future

All work happens in `nix-lab` only. Two branches:

```
nix-lab (working copy)
 ├─ dev   → daily development branch   (you work here)
 └─ main  → public release snapshot    (the deployed end product)
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
git push origin main        # over SSH, no token
git checkout dev            # back to dev
```

That is the entire release flow — a fast-forward merge + push. No `git rm -r`,
no copy, no script. The public "end product" (previously `nix-config`) is simply
the `main` branch of this one repo.

To deploy the release: `git checkout main && nixos-rebuild ...`, then
`git checkout dev`.

## Why we changed

Previously `nix-lab` (development) and `nix-config` (public release) were two
repos with **unrelated git histories** and different layouts. Every release was
a fragile manual `git rm -r` + copy that erased nix-config's history continuity.

We migrated to **one repo, two branches** (`dev` + `main`) where `main` is a
descendant of `dev` (a merge commit unifying both histories). This makes every
release a normal fast-forward merge. History is preserved; nothing is erased.
