# modules/network/ap/default.nix
#
# Access-point stack: hostapd + freeradius (+ dnsmasq for DHCP).
#
# Single switch for the whole bundle:
#
#   services.ap.enable = true;   # hostapd + freeradius + dnsmasq
#   services.ap.enable = false;  # none of them (default)
#
# Sub-modules are imported unconditionally but every one of them gates its
# config on `services.ap.enable`, so when disabled no AP service, interface
# address, firewall rule, or systemd unit from the bundle exists.

{ config, lib, ... }:

{
  options.services.ap = {
    enable = lib.mkEnableOption "the access-point stack (hostapd + freeradius + dnsmasq)";
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
  ];

  config = lib.mkIf config.services.ap.enable { };
}
