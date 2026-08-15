# common/default.nix
# All long-running daemons.
{ ... }:
{
  imports = [
    ./ai
    ./db
    # ./ap  # disabled: suspected cause of no usable init (Part 3)
    ./mail
    ./media
    ./monitoring
    ./network
    ./packages
    ./storage
    ./web
  ];
}
