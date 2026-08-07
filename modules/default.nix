# modules/default.nix
# All long-running daemons.
{ ... }:
{
  imports = [
    ./ai
    ./mail
    ./media
    ./monitoring
    ./web
    ./network
    ./storage
  ];
}
