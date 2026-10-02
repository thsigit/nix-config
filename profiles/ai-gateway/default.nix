# profiles/ai-gateway/default.nix
# Dedicated AI-Gateway profile — minimal system running only the AI stack:
# LiteLLM proxy (ai.home.arpa), Open WebUI (chat.home.arpa), llama.cpp (llama.home.arpa),
# whisper.cpp (whisper.home.arpa), opencode agent.
#
# This profile is ADDITIVE — it does not modify server/workstation/failsafe.
# Use: sudo nixos-rebuild switch --flake /srv/repo/nix-lab#ai-gateway

{ config, lib, pkgs, callPackage, home-manager, ... }:
let
  defaults = import ../../settings;
  inherit (defaults) user domain;
  inherit (defaults.directories) appdata www;
  inherit (defaults.ai) models;
  inherit (defaults.security) sslDir;
in
{
  ##########################################################################
  # Base system + network (minimal, no desktop)
  ##########################################################################

  imports = [
    ../../system
    # AI modules only — not the full common/ (no media, mail, ap, etc.)
    ../../common/ai
  ];

  ##########################################################################
  # Networking — static LAN IP so DNS (home.arpa) resolves reliably
  ##########################################################################

  networking = {
    hostName = "ai-gateway";
    inherit domain;
    extraHosts = ''
      ${defaults.network.lanIp} ai-gateway.${domain} ai-gateway
      ${defaults.network.lanIp} ai.${domain} ai
      ${defaults.network.lanIp} chat.${domain} chat
      ${defaults.network.lanIp} llama.${domain} llama
      ${defaults.network.lanIp} whisper.${domain} whisper
    '';
    networkmanager.enable = true;
    networkmanager.unmanaged = [ "interface-name:${defaults.network.lanInterface}" ];
    interfaces.${defaults.network.lanInterface}.ipv4.addresses = [{
      address = defaults.network.lanIp;
      prefixLength = defaults.network.lanPrefix;
    }];
    defaultGateway = defaults.network.gateway;
    nameservers = [ defaults.network.gateway "1.1.1.1" ];
  };

  ##########################################################################
  # SSH access for admin
  ##########################################################################

  users.users.${user.name} = {
    isNormalUser = true;
    description = "Sigit Prasetyo";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN4bBvw5pcH+7rwNWAHCxNrioPjyn66rVmEHPtS5U5eQ sigit@vantage"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHRqLBFFpPTyOvk8+YxfE5NeG8pqO/kEHJMHxLjS3doA sigit@FedoraWSL"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIIvSm/xr14Xb0Epv2bqnjgASZJmeavgC/QJGan45aE6 V2333"
    ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  ##########################################################################
  # Bootloader
  ##########################################################################

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  ##########################################################################
  # Time & locale
  ##########################################################################

  time.timeZone = defaults.timezone;
  i18n.defaultLocale = "en_US.UTF-8";

  ##########################################################################
  # Caddy — AI vhosts only (no homepage, no godmod3, etc.)
  ##########################################################################

  services.caddy = {
    enable = true;
    virtualHosts = {
      "ai.${domain}".extraConfig = ''
        tls ${sslDir}/homelab.crt ${sslDir}/homelab.key
        # Read-only LiteLLM endpoints: inject master key for keyless browser access
        @readonly path /health /health/liveness /health/readiness /health/services /v1/models /models /v1/model/info /model/info
        handle @readonly {
          reverse_proxy 127.0.0.1:4000 {
            header_up Authorization "Bearer {env.LITELLM_MASTER_KEY}"
          }
        }
        # Admin/write endpoints go to :8091 (requires key)
        handle /api/* {
          reverse_proxy 127.0.0.1:8091
        }
        # Frontend
        @frontend path / /litellm.js /ui/playground/* /stats.json
        handle @frontend {
          root * ${www}/ai
          file_server
        }
      '';
      "chat.${domain}".extraConfig = ''
        tls ${sslDir}/homelab.crt ${sslDir}/homelab.key
        reverse_proxy 127.0.0.1:8081
      '';
      "llama.${domain}".extraConfig = ''
        tls ${sslDir}/homelab.crt ${sslDir}/homelab.key
        reverse_proxy 127.0.0.1:8080
      '';
      "whisper.${domain}".extraConfig = ''
        tls ${sslDir}/homelab.crt ${sslDir}/homelab.key
        reverse_proxy 127.0.0.1:8090
      '';
    };
    environment.systemPackages = [ pkgs.caddy ];
  };

  systemd.services.caddy.serviceConfig.EnvironmentFile =
    [ config.sops.secrets."providers.env".path ];

  ##########################################################################
  # System packages — minimal toolkit
  ##########################################################################

  environment.systemPackages = with pkgs; [
    git vim curl wget btop jq yq
    util-linux smartmontools rsync
  ];

  ##########################################################################
  # Clean up: no desktop, no media, no mail, no AP
  ##########################################################################

  services.ap.enable = false;
  services.xserver.enable = false;
  services.printing.enable = false;

  ##########################################################################
  # System version
  ##########################################################################

  system.stateVersion = "26.05";
}
