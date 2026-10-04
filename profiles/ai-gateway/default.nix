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
  # Keys and base groups come from `system/ssh.nix` and `system/users.nix`.
  # Only the extra group below is local.
  ##########################################################################

  # The SSH authorized keys moved to `system/ssh.nix` on 2026-10-04; they used
  # to be duplicated here. `extraGroups` is a concatenating list option, so this
  # must stay a delta -- `system/users.nix` already grants
  # networkmanager/wheel/audio/video/podman/ydotool and repeating them here
  # would produce literal duplicates.
  users.users.${user.name}.extraGroups = [ "docker" ];

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