# system/grub-failsafe.nix
#
# Emergency grub failsafe entry.
#
# Adds a "NixOS - (Manual Edit)" menuentry that always boots the current
# generation. It is emitted natively by the grub installer via
# boot.loader.grub.extraEntries (no activation script, no recursion), so it
# coexists with the NixOS and "NixOS - All configurations" entries.
#
# It points at the stable profile symlink /nix/var/nix/profiles/system (which is
# repointed at the active generation on every switch) rather than the per-build
# toplevel, so the entry tracks the current generation without forcing an
# evaluation-time reference to config.system.build.toplevel (which would recurse).
#
# Workflow: with grub enabled, rebuild once so grub.cfg gains the full menu plus
# this entry, then flip back to systemd-boot (grub.cfg is left frozen as the
# failsafe). The kernel/initrd are read straight from /nix/store on the root
# filesystem, exactly like the standard NixOS grub entries.

{ config, ... }:

{
  boot.loader.grub.extraEntries = let
    prof = "/nix/var/nix/profiles/system";
    # Root filesystem UUID; grub reads the kernel/initrd from /nix/store on it.
    rootUuid = "7b14c665-b692-43de-a090-322a236e2c3b";
  in ''
    menuentry "NixOS - (Manual Edit)" --class nixos {
      search --set=drive1 --fs-uuid ${rootUuid}
      linux ($drive1)${prof}/kernel init=${prof}/init quiet loglevel=3 consoleblank=120 acpi_osi=Linux ahci.mobile_lpm_policy=0 root=fstab loglevel=4 lsm=landlock,yama,bpf
      initrd ($drive1)${prof}/initrd
    }
  '';
}
