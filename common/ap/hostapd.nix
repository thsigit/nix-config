# common/ap/hostapd.nix
{ config, pkgs, lib, ... }:

let
  ap = config.services.ap.interface;
  band = config.services.ap.band;
in
{
  services.hostapd = {
    enable = true;
    radios.${ap} = {
      inherit band;
      channel = 6;
      networks.${ap} = {
        ssid = "kebabtamalate";
        authentication.mode = "none";
        settings = {
          wpa = 2;
          wpa_key_mgmt = "WPA-EAP";
          ieee8021x = 1;
          auth_server_addr = "127.0.0.1";
          auth_server_port = 1812;
        };
        # auth_server_shared_secret is not in `settings` (it would be baked into
        # the Nix store). Append it at runtime from the sops-decrypted file.
        dynamicConfigScripts.eapSecret = pkgs.writeShellScript "hostapd-eap-secret" ''
          HOSTAPD_CONFIG=$1
          cat >> "$HOSTAPD_CONFIG" << EOF
          auth_server_shared_secret=$(cat ${config.sops.secrets."radius-secret".path})
          EOF
        '';
      };
    };
  };

  networking.interfaces.${ap}.ipv4.addresses = [{
    address = "192.168.4.1";
    prefixLength = 24;
  }];

  networking.networkmanager.unmanaged = [ "interface-name:${ap}" ];

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
}
