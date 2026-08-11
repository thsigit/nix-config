# common/security/sudo.nix

{ config, lib, pkgs, ... }:

let
  inherit (import ../settings) user;
in
{
  security.sudo = {
    enable = true;
    execWheelOnly = true;
    extraRules = [
      {
        users = [ user.name ];
        commands = [
          { command = "ALL"; options = [ "NOPASSWD" ]; }
        ];
      }
      # Require a password for nixos-rebuild even though passwordless sudo is
      # otherwise allowed. Intentional: prevents accidental/unattended rebuilds.
      {
        users = [ user.name ];
        commands = [
          { command = "/run/current-system/sw/bin/nixos-rebuild"; }
        ];
      }
    ];
  };
}
