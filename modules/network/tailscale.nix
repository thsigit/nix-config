# modules/network/tailscale.nix

{ config, pkgs, lib, ... }:

{
  services.tailscale = {
    enable = true;
    permitCertUid = "caddy";
    useRoutingFeatures = "server";
  };

  systemd.services.tailscale-gro = {
    description = "Optimize UDP GRO for Tailscale";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    path = [ pkgs.iproute2 pkgs.ethtool pkgs.gawk ];

    script = ''
      ethtool -K $(ip route get 8.8.8.8 | awk '{print $5}') rx-udp-gro-forwarding on rx-gro-list off
    '';
  };

  environment.systemPackages = with pkgs; [
    tailscale
  ];
}
