# modules/default.nix
# All long-running daemons.
{ ... }:
{
  imports = [
    ./ai
    ./db
    # ./ap
    ./mail
    ./media
    ./monitoring
    ./network
    ./packages
    ./storage
    ./web
  ];
}
