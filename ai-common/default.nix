# ai-common/default.nix
#
# AI gateway stack. Each leaf module owns its own defaults and is always-on
# when imported (mrtg-style standard) — this file is an index, plus the one
# piece of shared wiring the stack needs that no single leaf owns: hostname
# resolution for the vhosts the AI services are published under.
{ ... }:
let
  defaults = import ../settings;
  inherit (defaults) domain;
  inherit (defaults.network) lanIp;
in
{
  imports = [
    ./llama-cpp.nix
    ./opencode.nix
    ./open-webui.nix
    ./whisper.nix
    ./litellm
  ];

  ##########################################################################
  # Networking — name resolution for the AI vhosts
  #
  # These are the names the AI services are *published* under, so they belong
  # to the stack rather than to any one profile. Both #ai-gateway and
  # #workstation serve them; #server does not, because #server does not
  # import this directory.
  #
  # Moved here from `profiles/ai-gateway` on 2026-10-05. It was the last
  # delta standing between `workstation` and listing its base imports
  # directly instead of reaching them through `../ai-gateway`.
  #
  # `networking.extraHosts` is a plain list option, so this CONCATENATES with
  # the `homelab` entry from `system/networking.nix` rather than replacing it.
  # The static address, domain, gateway and nameservers all come from
  # `system/networking.nix` — do not repeat them here.
  ##########################################################################

  networking.extraHosts = ''
    ${lanIp} ai-gateway.${domain} ai-gateway
    ${lanIp} ai.${domain} ai
    ${lanIp} chat.${domain} chat
    ${lanIp} llama.${domain} llama
    ${lanIp} whisper.${domain} whisper
  '';
}
