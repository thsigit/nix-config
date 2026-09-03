# common/ap/hostapd.nix
{ config, pkgs, lib, ... }:

let
  defaults = import ../../settings;
  inherit (defaults.ap) ssid ip;
  ap = config.services.ap.interface;
  band = config.services.ap.band;
  # Derive the AP network prefix for the DHCP range (192.168.4.1 -> 192.168.4)
  apNet = lib.concatStringsSep "." (lib.take 3 (lib.splitString "." ip));
in
{
  config = lib.mkIf config.services.ap.enable {
    services.hostapd = {
      enable = true;
      radios.${ap} = {
        inherit band;
        channel = 6;
        networks.${ap} = {
          ssid = ssid;
          authentication.mode = "none";
          settings = {
            wpa = 2;
            wpa_key_mgmt = "WPA-EAP";
            ieee8021x = 1;
            auth_server_addr = "127.0.0.1";
            auth_server_port = 1812;
          };
          # auth_server_shared_secret must match the FreeRADIUS client hostapd
          # connects to. hostapd sends over loopback (127.0.0.1), which FreeRADIUS
          # matches to its built-in `localhost` client (secret testing123). Use
          # that same secret here or auth is silently dropped.
          dynamicConfigScripts.eapSecret = pkgs.writeShellScript "hostapd-eap-secret" ''
            HOSTAPD_CONFIG=$1
            cat >> "$HOSTAPD_CONFIG" << EOF
            auth_server_shared_secret=testing123
            EOF
          '';
        };
      };
    };

    networking.interfaces.${ap}.ipv4.addresses = [{
      address = ip;
      prefixLength = 24;
    }];

    networking.networkmanager.unmanaged = [ "interface-name:${ap}" ];
    networking.wireless.enable = lib.mkForce false;

    # Serve DHCP on the AP subnet (192.168.4.0/24) so wireless clients get an
    # address, while dnsmasq keeps serving the LAN in parallel (GAP #1 fix).
    services.dnsmasq.settings = {
      interface = lib.mkAfter [ ap ];
      listen-address = lib.mkAfter [ ip ];
      dhcp-range = [ "${apNet}.10,${apNet}.200,255.255.255.0,24h" ];
    };

    # Masquerade AP-client traffic so clients can reach the internet (GAP #2
    # fix). internalInterfaces marks wlp2s0 traffic out the default gateway.
    networking.nat = {
      enable = true;
      internalInterfaces = [ ap ];
    };

    # The global firewall blocks DNS (port 53) off the AP interface. Open it so
    # AP clients can use dnsmasq at ${ip} for name resolution.
    networking.firewall.interfaces.${ap} = {
      allowedUDPPorts = [ 53 ];
      allowedTCPPorts = [ 53 ];
    };

    # The iwlwifi radio comes up soft-blocked on some boots (rfkill), which makes
    # hostapd fail at interface init and — because dnsmasq depends on hostapd —
    # takes DHCP/DNS down too. Unblock the radio before hostapd starts.
    systemd.services.rfkill-unblock = {
      description = "Unblock wireless radios blocked by rfkill";
      wantedBy = [ "multi-user.target" ];
      before = [ "hostapd.service" ];
      path = [ pkgs.util-linux ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        rfkill unblock wifi || true
      '';
    };

    systemd.services.hostapd.after = [ "rfkill-unblock.service" ];
    systemd.services.hostapd.requires = [ "rfkill-unblock.service" ];
  };
}
