# common/web/default.nix
{ ... }:
{
  imports = [ ./caddy.nix ./nix-journal.nix ./blog.nix ./article.nix ./academic.nix ];
}
