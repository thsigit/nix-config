# profiles/workstation/default.nix
# Desktop front-end for the same physical machine as `server`
# (Toshiba Portege R30-C).
#
# Composition: `system/` + `common/` + `ai-common/` + the desktop delta
# (XFCE, home-manager, desktop packages). As of 2026-10-05 it names those
# three directories itself rather than reaching them through `../ai-gateway`,
# so no profile in this repo imports another profile.
#
#   system/  +  common/  +  ai-common/  +  desktop
#     └───────────── shared ─────────────┘
#
# The roles still cascade — #system is the base, #server is that base as a
# headless box, #ai-gateway adds the AI stack, #workstation adds a desktop —
# but the *code* does not. Each profile lists the layers it wants. See
# AGENTS.md, "Layering".

{ home-manager, ... }:
let
  defaults = import ../../settings;
  inherit (defaults) user;
in
{
  imports = [
    ../../system
    ../../common
    ../../ai-common
    home-manager.nixosModules.home-manager
    ./xfce4.nix
    ./packages.nix
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${user.name} = import ./home.nix;
  };

  # The AP bundle is declared by `common/ap`, which is what defines the
  # `services.ap` option in the first place. Disabled here so the desktop
  # does not fight `system/networking.nix` over the wireless NIC.
  services.ap.enable = false;
}
