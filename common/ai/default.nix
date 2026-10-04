# common/ai/default.nix — DEPRECATED re-export shim (transitional)
#
# The AI gateway stack graduated from `common/ai/` to `ai-common/` at the repo
# root on 2026-10-04, so that it can be inherited by profile modules rather than
# dragged in through the `common/` barrel.
#
# This shim keeps `imports = [ ../../common/ai ];` working for any module that has
# not been migrated yet. It has no options and no config of its own — it only
# re-exports `ai-common/`.
#
# Nothing imports this path any more (see `common/default.nix`, which no longer
# lists `./ai`). Delete this directory once no out-of-tree module references
# `common/ai`.
{ ... }:
{
  imports = [ ../../ai-common ];
}