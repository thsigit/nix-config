# system/ssh.nix

{ config, ... }:

let
  inherit (import ../settings) user;
in
{
  services.openssh = {
    enable = true;
    settings = {
     PasswordAuthentication = false;
     PermitRootLogin = "no";
    };
  };

  # Register user SSH keys. nixpkgs renders these via `authKeysFiles` in
  # services/networking/ssh/sshd.nix to /etc/ssh/authorized_keys.d/<user>, and
  # sshd reads that path -- so these DO take effect.
  #
  # `failsafe` deliberately does NOT import ../../system, so it keeps its own
  # inline copy of the same three keys; that duplication is intentional, it is
  # what keeps recovery independent of this tree.
  users.users.${user.name}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN4bBvw5pcH+7rwNWAHCxNrioPjyn66rVmEHPtS5U5eQ sigit@vantage"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHRqLBFFpPTyOvk8+YxfE5NeG8pqO/kEHJMHxLjS3doA sigit@FedoraWSL"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIIvSm/xr14Xb0Epv2bqnjgASZJmeavgC/QJGan45aE6 V2333"
  ];
}
