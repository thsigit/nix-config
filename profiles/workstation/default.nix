# profiles/workstation/default.nix
# Desktop front-end for the same physical machine as `server`
# (Toshiba Portege R30-C). Composition (2026-10-04 refactor):
#
#   system/  ->  common/  ->  server  ->  ai-common/  ->  ai-gateway  ->  workstation
#
# This profile therefore inherits the whole server + AI stack and adds only the
# desktop delta: XFCE, home-manager and the desktop package set. It must NOT
# re-import `system/` or `common/` — that would duplicate every module and, for
# list options, silently concatenate duplicates.

{ pkgs, home-manager, ... }:
let
  defaults = import ../../settings;
  inherit (defaults) user;
in
{
  imports = [
    ../ai-gateway
    home-manager.nixosModules.home-manager
    ./xfce4.nix
    ./packages.nix
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${user.name} = import ./home.nix;
  };

  # The AP bundle is inherited from `server` via `common/ap`, which is what
  # declares `services.ap` in the first place. Disabled here so the desktop
  # does not fight `system/networking.nix` over the wireless NIC.
  services.ap.enable = false;
}