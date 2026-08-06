# programs/default.nix
# All interactive applications (user-invoked).

{ ... }:

{
  imports = [
    ./packages.nix
    ./ydotool.nix
    ./bash.nix
    ./tmux.nix
    ./vim.nix
    ./git.nix
    ./fzf.nix
    ./htop.nix
    ./bandwhich.nix
    ./iftop.nix
    ./iotop.nix
    ./tcpdump.nix
    ./traceroute.nix
    ./wireshark.nix
  ];
}
