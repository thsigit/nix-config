# profiles/failsafe/default.nix
#
# Failsafe — minimal recovery configuration for machine portege-r30c.
# Use as last-resort fallback when the full flake fails to boot:
#
#   sudo nixos-rebuild switch --flake .#failsafe
#
# Contains only: a basic NixOS system, SSH access, static WAN IP, and a
# small recovery toolkit (expand later). Keeps /srv/repo/nix-orig as
# reference only.
#
# NOTE: this profile deliberately does NOT import ../../system (so a broken
# system/ does not take down recovery). Network values are read from
# settings/ (which is standalone and safe) to avoid re-hardcoding them.

{ config, lib, pkgs, ... }:
let
  defaults = import ../../settings;
  inherit (defaults) domain;
  inherit (defaults.network) lanInterface lanIp lanPrefix gateway;
in

{
  # Bootloader — stock systemd-boot, same as a fresh NixOS install.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "homelab";
    inherit domain;
    extraHosts = ''
      ${lanIp} homelab.${domain} homelab
    '';
    # Static WAN IP so the box is always reachable at ${lanIp}.
    networkmanager.enable = true;
    networkmanager.unmanaged = [ "interface-name:${lanInterface}" ];
    interfaces.${lanInterface}.ipv4.addresses = [{
      address = lanIp;
      prefixLength = lanPrefix;
    }];
    defaultGateway = gateway;
    nameservers = [ gateway "1.1.1.1" ];
  };

  time.timeZone = "Asia/Makassar";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.sigit = {
    isNormalUser = true;
    description = "Sigit Prasetyo";
    extraGroups = [ "networkmanager" "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN4bBvw5pcH+7rwNWAHCxNrioPjyn66rVmEHPtS5U5eQ sigit@vantage"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHRqLBFFpPTyOvk8+YxfE5NeG8pqO/kEHJMHxLjS3doA sigit@FedoraWSL"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIIvSm/xr14Xb0Epv2bqnjgASZJmeavgC/QJGan45aE6 V2333"
    ];
  };

  services.openssh = {
    enable = true;
    settings = {
      # Password auth stays enabled as a fallback in case SSH keys are lost.
      PermitRootLogin = "no";
    };
  };

  # Recovery toolkit — define the full list later.
  environment.systemPackages = with pkgs; [
    # Nix / config
    git
    vim
    nix-tree
    nix-diff

    # Filesystems / disks
    util-linux
    e2fsprogs
    gptfdisk
    parted
    dosfstools
    smartmontools

    # EFI / boot
    efibootmgr

    # Storage
    cryptsetup
    lvm2
    rsync

    # Network
    curl
    wget
    dnsutils
    iproute2
    iputils
    ethtool
    tcpdump
    openssh

    # Diagnostics
    btop
    tree
    file
    binutils
    lsof
    psmisc
    pciutils
    usbutils
    dmidecode
    lshw
    lm_sensors

    # Troubleshooting
    strace
  ];

  system.stateVersion = "26.05";
}
