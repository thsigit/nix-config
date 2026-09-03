# common/default.nix
# All long-running daemons.
{ ... }:
{
  imports = [
    ./ai
    ./ap
    ./mail
    ./media
    ./monitoring
    ./network
    ./packages
    ./security
    ./storage
    ./web
  ];
}
