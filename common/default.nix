# common/default.nix
# All long-running daemons.
{ ... }:
{
  imports = [
    ./ai
    # ./ap  # disabled: suspected cause of no usable init (Part 3)
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
