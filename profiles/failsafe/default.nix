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

{ config, lib, pkgs, ... }:

{
  # Bootloader — stock systemd-boot, same as a fresh NixOS install.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "homelab";
    domain = "home.arpa";
    extraHosts = ''
      192.168.1.3 homelab.home.arpa homelab
    '';
    # Static WAN IP so the box is always reachable at 192.168.1.3.
    networkmanager.enable = true;
    networkmanager.unmanaged = [ "interface-name:enp0s31f6" ];
    interfaces.enp0s31f6.ipv4.addresses = [{
      address = "192.168.1.3";
      prefixLength = 24;
    }];
    defaultGateway = "192.168.1.1";
    nameservers = [ "192.168.1.1" "1.1.1.1" ];
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
