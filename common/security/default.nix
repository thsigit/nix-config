# common/security/default.nix
{ ... }:
{
  imports = [ ./pki.nix ./sops.nix ];
}
