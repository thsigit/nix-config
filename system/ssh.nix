# common/security/ssh.nix

{ config, ... }:

{
  services.openssh = {
    enable = true;
    # settings = {
    #  PasswordAuthentication = false;
    #  PermitRootLogin = "no";
    # };
  };

  # Register user SSH keys
  # users.users.sigit = {
  #  openssh.authorizedKeys.keys = [
  #    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN4bBvw5pcH+7rwNWAHCxNrioPjyn66rVmEHPtS5U5eQ sigit@vantage"
  #    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHRqLBFFpPTyOvk8+YxfE5NeG8pqO/kEHJMHxLjS3doA sigit@FedoraWSL"
  #    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIIvSm/xr14Xb0Epv2bqnjgASZJmeavgC/QJGan45aE6 V2333"
  #  ];
  # };
}
