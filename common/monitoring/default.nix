# common/monitoring/default.nix
#
# Directory index only. Each leaf module owns its own enable/defaults, so
# importing this directory enables the full monitoring stack. Per-service
# overrides belong at the profile level, not here.
{ ... }:
{
  imports = [
    ./cockpit.nix
    ./darkstat.nix
    ./mrtg.nix
  ];
}
