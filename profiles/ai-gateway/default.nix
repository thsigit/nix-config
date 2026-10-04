# profiles/ai-gateway/default.nix
# Dedicated AI-Gateway profile — the base system plus the AI stack:
# LiteLLM proxy (ai.home.arpa), Open WebUI (chat.home.arpa), llama.cpp (llama.home.arpa),
# whisper.cpp (whisper.home.arpa), opencode agent.
#
# Composition (2026-10-04 refactor): the base modules (`system/` + `common/`) plus
# `ai-common/`, which graduated out of `common/ai/` to the repo root so it can be
# listed here directly instead of being dragged in by the `common/` barrel.
# Use: sudo nixos-rebuild switch --flake /srv/repo/nix-lab#ai-gateway
#
# Deliberately NOT importing `../server`: this profile aggregates the base modules
# itself rather than depending on a sibling profile. Profiles are meant to be
# alternatives you pick between, not layers to inherit, and importing one would
# also drag in whatever headless/desktop policy that profile happens to carry.
#
# Headless-ness needs no declaration here: `services.xserver.enable` and
# `services.printing.enable` both default to false in nixpkgs, and this profile
# does not touch them.
#
# This profile is now nothing but its import list. Everything that used to make it
# distinguishable from `server` has been pushed down to the layer that owns it:
#   - the AI vhost name resolution moved to `ai-common/default.nix` (2026-10-05),
#     because those hostnames belong to the AI services, not to this profile;
#   - the Caddy provider-env moved to `ai-common/litellm/litellm.nix`;
#   - `services.openssh.settings` moved to `system/ssh.nix`;
#   - `util-linux rsync` and the `docker` group were dropped as redundant.
# The AI stack itself is entirely inside `ai-common/`. That is the whole reason
# `server` can be the same system minus AI rather than a different system.

{ ... }:
{
  imports = [
    ../../system
    ../../common
    ../../ai-common
  ];
}
