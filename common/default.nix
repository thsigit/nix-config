# common/default.nix
# All long-running daemons.
#
# The AI gateway stack is NOT here: it graduated to `ai-common/` at the repo root
# on 2026-10-04 so that profiles can inherit it explicitly (see
# `profiles/ai-gateway/default.nix`). A re-export shim remains at
# `common/ai/default.nix` for out-of-tree consumers during the transition.
{ ... }:
{
  imports = [
    ./ap
    ./mail
    ./media
    ./monitoring
    ./network
    ./packages
    ./security
    ./storage
    ./web
  ];
}