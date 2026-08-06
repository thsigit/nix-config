# services/default.nix
# All long-running daemons.
{ ... }:
{
  imports = [
    ./ai
    ./media
    ./monitoring
    ./web
    ./network
    ./storage
  ];
}
