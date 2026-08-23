# common/web/default.nix
{ ... }:
{
  imports = [ ./caddy.nix ./codebot.nix ./journal.nix ];
}
