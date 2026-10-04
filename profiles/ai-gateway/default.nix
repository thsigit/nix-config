# profiles/ai-gateway/default.nix
# Dedicated AI-Gateway profile — the base system plus the AI stack:
# LiteLLM proxy (ai.home.arpa), Open WebUI (chat.home.arpa), llama.cpp (llama.home.arpa),
# whisper.cpp (whisper.home.arpa), opencode agent.
#
# Composition (2026-10-04 refactor): the base modules (`system/` + `common/`) plus
# `ai-common/`, which graduated out of `common/ai/` to the repo root so it can be
# listed here directly instead of being dragged in by the `common/` barrel.
# Use: sudo nixos-rebuild switch --flake /srv/repo/nix-lab#ai-gateway
#
# Deliberately NOT importing `../server`: this profile aggregates the base modules
# itself rather than depending on a sibling profile. Profiles are meant to be
# alternatives you pick between, not layers to inherit, and importing one would
# also drag in whatever headless/desktop policy that profile happens to carry.
#
# Headless-ness needs no declaration here: `services.xserver.enable` and
# `services.printing.enable` both default to false in nixpkgs, and this profile
# does not touch them. That also keeps the door open for a desktop profile to
# build on this one without a module-priority conflict.

{ config, pkgs, ... }:
let
  defaults = import ../../settings;
  inherit (defaults) user domain;
  inherit (defaults.network) lanIp;
in
{
  ##########################################################################
  # Base system + AI modules
  ##########################################################################

  imports = [
    ../../system
    ../../common
    ../../ai-common
  ];

  ##########################################################################
  # Networking — AI vhost name resolution
  #
  # `networking.extraHosts` is a plain list option, so this CONCATENATES with
  # the `homelab` entry from `system/networking.nix` rather than replacing it.
  # The static address, domain, gateway and nameservers all come from
  # `system/networking.nix` — do not repeat them here.
  ##########################################################################

  networking.extraHosts = ''
    ${lanIp} ai-gateway.${domain} ai-gateway
    ${lanIp} ai.${domain} ai
    ${lanIp} chat.${domain} chat
    ${lanIp} llama.${domain} llama
    ${lanIp} whisper.${domain} whisper
  '';

  ##########################################################################
  # SSH access for admin
  #
  # The keys stay here for now: `system/ssh.nix` keeps its own copy commented
  # out. `isNormalUser`, `description` and the base `extraGroups` come from
  # `system/users.nix`.
  ##########################################################################

  users.users.${user.name} = {
    # Only the delta. `system/users.nix` already grants
    # networkmanager/wheel/audio/video/podman/ydotool; listing them again
    # here would concatenate duplicates.
    extraGroups = [ "docker" ];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN4bBvw5pcH+7rwNWAHCxNrioPjyn66rVmEHPtS5U5eQ sigit@vantage"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHRqLBFFpPTyOvk8+YxfE5NeG8pqO/kEHJMHxLjS3doA sigit@FedoraWSL"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIIvSm/xr14Xb0Epv2bqnjgASZJmeavgC/QJGan45aE6 V2333"
    ];
  };

  services.openssh.settings = {
    PermitRootLogin = "no";
    PasswordAuthentication = false;
  };

  ##########################################################################
  # Caddy — feed the sops-provided provider env to the unit
  #
  # `services.caddy.enable` and the `pkgs.caddy` package both come from
  # `common/web/caddy.nix`; the AI modules publish their vhosts through
  # `services.caddy.services`.
  ##########################################################################

  systemd.services.caddy.serviceConfig.EnvironmentFile =
    [ config.sops.secrets."providers.env".path ];

  ##########################################################################
  # System packages — delta only
  #
  # `common/packages` already provides curl, wget, jq, yq, btop,
  # smartmontools, git, vim, nix-tree and friends. These two are the gap.
  ##########################################################################

  environment.systemPackages = with pkgs; [
    util-linux rsync
  ];
}