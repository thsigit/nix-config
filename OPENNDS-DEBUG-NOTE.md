# OPENNDS DEBUG NOTE — guest splash never registers clients (Aug 2026 → Sep 2026 update)

**Status:** RESOLVED 2026-09-03 — openNDS DROPPED from the AP bundle. AP is now a plain open hotspot (hostapd + freeradius + dnsmasq/DHCP, NAT via networking.nat) with verified working internet for AP clients (3CPO). Captive portal abandoned for now. The earlier `fwhook_enabled '0'` 'bypass' was a red herring (it is an OpenWrt-only option and does NOT disable openNDS's nft firewall).

---

## UPDATE 2026-09-03: CURRENT STATE

### What's Fixed
1. **Boot failure root-caused and fixed** — `system.activationScripts.freeradius-certs` (openssl + dhparam at switch) caused `switch root target contains no usable init`. Moved to `freeradius-cert-init.service` (oneshot, marker file, explicit deps). Commit `7961f47` on `dev`.
2. **openNDS activation script removed** — Refactored `common/ap/opennds.nix` to use `preStart` in systemd service (copies resources, writes config with sops faskey). Zero activation scripts in new generation.
3. **Repo cleanup** — Removed duplicate nix-lab content from `/srv/repo/` (loose files + dirs).
4. **Build & boot** — Full AP bundle (hostapd + freeradius + openNDS) builds cleanly (`nixos-rebuild build`), boots gen 220, all services active.

### What's Broken (NEW FINDING)
- **openNDS client tracking completely broken** — `Current clients: 0`, authentications: 0.
- **`nds_mangle ndsOUT` chain is EMPTY** — should contain per-client mark rules for pre-auth/auth classification.
- **Root cause:** nftables/iptables hybrid conflict.
  - Base system NAT uses iptables-compat (`networking.nat` + `nixos-nat-pre`, mark 0x1).
  - openNDS 11 defaults to nftables, installs `nds_filter`, `nds_mangle`, `nds_nat` (inet family).
  - Client tracking requires mangle chain population → fails in hybrid → no marks → no clients registered → `ndsNET` rejects ALL pre-auth traffic (1295 pkts rejected in test).

### Evidence (Sep 2026)
```
# ndsctl status
Current clients: 0
Trusted MAC addresses: ["ea:0a:02:8a:8f:08"]  (3CPO added manually)
Authentications since start: 0

# nft list chain inet nds_mangle ndsOUT
chain ndsOUT { }   # EMPTY — client marking never happens

# nft list chain inet nds_filter ndsNET
counter packets 1295 bytes 113853 reject   # ALL pre-auth traffic rejected
```

### What Was Tried
- `ndsctl trust ea:0a:02:8a:8f:08` → MAC added to trusted list, but openNDS never registers client → no auto-auth.
- openNDS restart → `ndsOUT` still empty.
- Verified: 3CPO connects, gets IP 192.168.4.196, DNS resolves, MHD on :2050 responds locally (403 for / without session).

### RESOLUTION (2026-09-03) — openNDS dropped; open AP restored
`fwhook_enabled '0'` was tried (commit `34adad3`) but is a **false bypass**: it is an
OpenWrt-only option (`fwhook_enabled` re-inserts openNDS nftables on OpenWrt FW4 restart)
and has NO effect on NixOS. openNDS 11 still `Initializing firewall rules` on every start
and re-created its `nds_*` tables regardless.

Decision: **drop openNDS from the AP bundle** and run a plain open hotspot. Changes:
- `common/ap/default.nix`: removed `./opennds.nix` import; bundle now hostapd + freeradius
  only (NAT/DHCP/DNS via `networking.nat` + dnsmasq on `192.168.4.1`).
- Deleted `common/ap/opennds.nix` and `secrets/opennds.yaml`; removed `opennds-faskey`
  sops secret (`common/security/sops.nix`) and the `opennds` flake input (`flake.nix`).
- `networking.nat` provides the same mark-0x1 -> masquerade-out-`enp0s31f6` NAT the old
  pre-openNDS `common/ap/router.nix` did (that file was removed at commit `9b40809`).

Critical gotcha: **openNDS nft tables outlive the service.** After the switch removed
`opennds.service`, the stale kernel tables (`nds_filter`, `nds_mangle`, `nds_nat`) were
still wired into the FORWARD hook (priority -100) and rejected ALL AP traffic — so 3CPO
had no internet even after the switch. Fix: `nft delete table inet nds_{filter,mangle,nat}`.
Once deleted they cannot regenerate (openNDS fully out of the build).

Verified on 3CPO: NAT masquerade counter increments live (196->204->209 pkts), DNS
resolves via `192.168.4.1`, forward chain accepts `wlp2s0`. Internet works.

---

## ORIGINAL INVESTIGATION (Aug 2026 — PRESERVED FOR REFERENCE)

### 1. Symptom
Guest phone "3CPO" (MAC `ea:0a:02:8a:8f:08`) connects to openNDS SSID but never gets splash page.
- `ndsctl json` → `client_list_length: 0`, `client authentications since start: 0`
- AP works: WPA2-EAP auth + association OK, DHCP/DNS served.

### 2. Environment (Historical)
- Repo: `/srv/repo/nix-config` (branch `main`); homelab `192.168.1.3`.
- AP stack: `services.ap.enable`; files in `common/network/ap/`.
- openNDS 11.0.0, `gatewayport 2050`, `fwhook_enabled 1`, FAS Secure Level 1.

### 3. Key Evidence (Aug 2026 Capture)
- 33 SYN from phone → 192.168.4.1:2050 → **0 SYN-ACK** (handshake never completes).
- 92 DNS queries → **0 replies**.
- Netfilter counters: SYN/DNS **accepted** in input hooks (141/1851 pkts).
- ARP/ICMP replies **do reach phone** (netfilter-generated).
- MHD works locally (`curl localhost:2050/mhdstatus` → 200).
- No conntrack entries for phone; rp_filter loose; routing sane.

### 4. Ruled Out
- openNDS fwhook not running (openNDS 11 has no separate fwhook)
- Detection primitives broken (standalone `libopennds.sh dhcpcheck` works)
- MHD crashed (listening, local curls 200)
- Netfilter dropping SYN/DNS (counters prove acceptance)
- Conntrack invalid-drop (counter = 0)
- rp_filter strict (wlp2s0 = loose)
- Flowtable offload (zero flows added)
- Phone ARP/MAC unknown (neigh has lladdr)
- Wrong source-address routing (reply route correct)

### 5. Leading Hypotheses (from Aug 2026)
1. **Locally-generated replies to wireless STA silently not transmitted** — socket TX path broken for STA, netfilter-generated packets work.
2. **SYN/DNS delivered to different netns** (podman/netavark interference).
3. **Policy routing / fwmark trap** — openNDS marks (bits 16-17) overlap fwmark 0xff0000 mask with unreachable rule 5250.
4. **iwlwifi AP-mode quirk with this client** — try second device / open SSID.

---

## NEXT STEPS (for next agent)

### Done — 2026-09-03
1. `fwhook_enabled '0'` tried, proven ineffective (OpenWrt-only; openNDS still inits nft).
2. openNDS dropped from the bundle; open AP verified working for 3CPO.
3. Stale `nds_*` nft tables flushed (the real blocker after the switch).

### If a captive portal is ever wanted again
1. Do NOT re-add openNDS blindly — its nft client-tracking assumes it owns the firewall
   and fails silently under iptables-compat NAT (`ndsOUT` mangle stays empty).
2. Options to evaluate: fix the nft/iptables hybrid (real work), or use a different
   portal solution that works with NixOS `networking.nat`.
3. If openNDS is re-added: remember its nft tables persist after the service stops; a
   clean removal must delete `nds_filter` / `nds_mangle` / `nds_nat`.

## Files / Artifacts (Current)

| File | Role |
|------|------|
| `/srv/repo/nix-lab/common/ap/freeradius.nix` | Refactored (oneshot cert-init) |
| `/srv/repo/nix-lab/common/ap/hostapd.nix` | Hostapd + DHCP + NAT + DNS firewall |
| `/srv/repo/nix-lab/common/ap/default.nix` | Imports hostapd + freeradius (no openNDS) |

---

## Invariants / Lessons

- **Never put long-running crypto in `system.activationScripts`** — breaks initrd pivot. Use oneshot service with marker file.
- **openNDS nftables mode assumes it owns the firewall** — when base system uses iptables-compat NAT, client tracking fails silently.
- **`fwhook_enabled '0'` is NOT a bypass** — it is OpenWrt-only and does not stop openNDS's nft firewall.
- **openNDS nft tables persist after the service stops**; removing openNDS requires deleting `nds_*` tables.
- **The AP bundle is now boot-safe and internet-functional** as a plain open hotspot. Captive portal abandoned (2026-09-03).

---

## Related Past Notes
- 2026-08-10: switch-root-target-contains-no-usable-init-part-1.md
- 2026-08-11: switch-root-target-contains-no-usable-init-part-2.md
- 2026-08-12: switch-root-target-contains-no-usable-init-part-3.md
- 2026-08-13: boot-recovery-part-5.md
- 2026-08-16: switch-root-target-contains-no-usable-init-part-4.md
- 2026-08-21: switch-root-target-contains-no-usable-init-part-5.md
- 2026-07-25 through 2026-08-01: captive-portal-and-access-point-bundle-part-1 through part-6.md
- 2026-08-12: captive-portal-and-access-point-bundle-part-7.md
- 2026-09-03: captive-portal-and-access-point-bundle-part-8.md (this session)