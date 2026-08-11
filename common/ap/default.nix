# common/ap/default.nix
#
# Access-point stack: hostapd + freeradius + opennds (+ dnsmasq for DHCP).
#
# Single switch for the whole bundle:
#
#   services.ap.enable = true;   # hostapd + freeradius + opennds (default when this dir is imported)
#   services.ap.enable = false;  # none of them
#
# Sub-modules are imported unconditionally but every one of them gates its
# config on `services.ap.enable`, so when disabled no AP service, interface
# address, firewall rule, or systemd unit from the bundle exists.
#
# The sub-modules are independent of each other: removing or commenting any
# single import below leaves the rest building and working.

{ config, lib, ... }:

{
  options.services.ap = {
    enable = lib.mkEnableOption "the access-point stack (hostapd + freeradius + opennds)";
    interface = lib.mkOption {
      type = lib.types.str;
      default = "wlp2s0";
      description = "Wireless access point network interface";
    };
    band = lib.mkOption {
      type = lib.types.str;
      default = "2g";
      description = "Wireless band for the access point (2g or 5g)";
    };
  };

  imports = [
    ./hostapd.nix
    ./freeradius.nix
    ./opennds.nix
  ];

  # Importing this directory enables the whole bundle. A profile can still
  # override with services.ap.enable = false to keep the modules imported but
  # inert.
  config.services.ap.enable = true;
}
