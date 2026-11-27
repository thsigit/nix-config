# ai-common/kaggle-proxy.nix
# Publish the WSL-hosted Kaggle LLM proxy as kaggle.home.arpa.
# Upstream arrives on homelab loopback via the SSH reverse tunnel from WSL
# (kaggle-proxy-tunnel.service), which forwards to kaggle-proxy.service there.
{ ... }:
{
  services.caddy.services.kaggle = {
    port = 8087;
    visibility.lan = true;
    visibility.tailscale = true;
  };
}
