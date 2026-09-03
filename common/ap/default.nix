# common/ap/default.nix
#
# Access-point stack: hostapd + freeradius + opennds (+ dnsmasq for DHCP).
#
# Single switch for the whole bundle:
#
#   services.ap.enable = true;   # hostapd + freeradius + opennds
#   services.ap.enable = false;  # none of them (default — profiles set this)
#
# Sub-modules are imported unconditionally but every one of them gates its
# config on `services.ap.enable`, so when disabled no AP service, interface
# address, firewall rule, or systemd unit from the bundle exists.
#
# The sub-modules are independent of each other: removing or commenting any
# single import below leaves the rest building and working.

{ config, lib, ... }:

let
  defaults = import ../../settings;
  inherit (defaults.ap) interface band;
in
{
  options.services.ap = {
    enable = lib.mkEnableOption "the access-point stack (hostapd + freeradius + opennds)";
    interface = lib.mkOption {
      type = lib.types.str;
      default = interface;
      description = "Wireless access point network interface";
    };
    band = lib.mkOption {
      type = lib.types.str;
      default = band;
      description = "Wireless band for the access point (2g or 5g)";
    };
  };

  imports = [
    ./hostapd.nix
    ./freeradius.nix
    ./opennds.nix
  ];

  # Profiles (workstation, server) set services.ap.enable = true to activate
  # the bundle. When disabled (the default), no AP service, interface address,
  # firewall rule, or systemd unit from this bundle exists.
}
