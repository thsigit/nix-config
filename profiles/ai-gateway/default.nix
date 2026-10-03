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
  # Base system + AI modules + Caddy (for services.caddy.services option)
  ##########################################################################

  imports = [
    ../../system
    ../../common/security
    ../../common/ai
    ../../common/web/caddy.nix
  ];

  ##########################################################################
  # Networking — static LAN IP so DNS (home.arpa) resolves reliably
  ##########################################################################

  networking = {
    hostName = lib.mkForce "ai-gateway";
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
  # Time & locale (system module also sets these, but we override for clarity)
  ##########################################################################

  time.timeZone = defaults.timezone;
  i18n.defaultLocale = "en_US.UTF-8";

  ##########################################################################
  # System packages — minimal toolkit
  ##########################################################################

  environment.systemPackages = with pkgs; [
    git vim curl wget btop jq yq
    util-linux smartmontools rsync
    caddy
  ];

  ##########################################################################
  # Caddy — use generated vhosts from services.caddy.services (AI modules)
  # The homelab homepage vhosts will also be generated but that's fine for build.
  ##########################################################################

  services.caddy = {
    enable = true;
  };

  systemd.services.caddy.serviceConfig.EnvironmentFile =
    [ config.sops.secrets."providers.env".path ];

  ##########################################################################
  # Clean up: no desktop, no media, no mail, no AP
  ##########################################################################

  services.xserver.enable = false;
  services.printing.enable = false;

  ##########################################################################
  # System version — inherited from system module (25.11)
  ##########################################################################

  # system.stateVersion = "25.11";  # defined in ../../system
}
