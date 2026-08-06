# modules/network/dnsmasq.nix

{ config, pkgs, ... }:

{ 
  services.dnsmasq = {
    enable = true;

    settings = {

      interface = [
        "tailscale0"
        "enp0s31f6"
      ];

      bind-interfaces = true;
      listen-address = [
        "127.0.0.1"
        "100.85.193.9"
        "192.168.1.3"
      ];

      # Local homelab domains
      address = [
        "/homelab.home.arpa/100.85.193.9"
        "/wallabag.home.arpa/100.85.193.9"
        "/darkstat.home.arpa/100.85.193.9"
        "/litellm.home.arpa/100.85.193.9"
      ];

    };
  };
  
  systemd.services.dnsmasq = {
    after = [
      "network-online.target"
      "tailscaled.service"
    ];

    wants = [
      "network-online.target"
      "tailscaled.service"
    ];
  };

  environment.systemPackages = with pkgs; [
    dnsmasq
  ];
}
