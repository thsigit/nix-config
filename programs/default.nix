# programs/default.nix
# All interactive applications (user-invoked).
{ ... }:
{
  imports = [
    ./git.nix
    ./neovim.nix
    ./go.nix
    ./nodejs.nix
    ./jq.nix
    ./shell.nix
    ./fzf.nix
    ./curl.nix
    ./htop.nix
    ./tree.nix
    ./nix.nix
    ./dig.nix
    ./openssl.nix
    ./copyparty.nix
    ./sqlite.nix
    ./hardware.nix
    ./ncmpcpp.nix
    ./mpv.nix
    ./yewtube.nix
    ./tlp.nix
    ./bc.nix
    ./tmuxai.nix
  ];
}
