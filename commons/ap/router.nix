# commons/ap/router.nix
{ config, pkgs, lib, ... }:

let
  ap = config.services.ap.interface;
in
{
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  # Manual NAT via nftables for openNDS clients
  systemd.services.nat-setup = {
    description = "Setup NAT for openNDS clients";
    wantedBy = [ "network-online.target" ];
    after = [ "network-online.target" "nftables.service" ];
    path = with pkgs; [ nftables ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Dedicated chains for openNDS NAT: flush only OUR chains so we never
      # destroy rules that other modules (or networking.nat) put in the
      # shared nixos-nat-* chains.
      nft add table ip nat 2>/dev/null || true
      nft add chain ip nat opennds-pre '{ type nat hook prerouting priority 0; }' 2>/dev/null || true
      nft add chain ip nat opennds-post '{ type nat hook postrouting priority 0; }' 2>/dev/null || true
      nft flush chain ip nat opennds-pre
      nft flush chain ip nat opennds-post
      nft add rule ip nat opennds-pre iifname "${ap}" meta mark set mark or 0x1
      nft add rule ip nat opennds-post oifname "enp0s31f6" meta mark \& 0x1 != 0 masquerade
    '';
    postStop = ''
      nft flush chain ip nat opennds-pre 2>/dev/null || true
      nft flush chain ip nat opennds-post 2>/dev/null || true
    '';
  };

  systemd.services.nat-setup.restartIfChanged = false;
}
