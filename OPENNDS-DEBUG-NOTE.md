# OPENNDS DEBUG NOTE — guest splash never registers clients (Aug 2026)

**Status:** INVESTIGATION PAUSED. Root cause NOT yet confirmed. Handoff note for the
next agent. Do not re-read this whole file — start at "LEADING HYPOTHESES" and "NEXT
STEPS" below, then consult Evidence sections as needed.

---

## 1. Symptom

A guest phone ("3CPO", MAC `ea:0a:02:8a:8f:08`, IP `192.168.4.115`) connects to the
openNDS-managed SSID (WPA2-EAP/PEAP via hostapd, `wlp2s0`). It performs Android
captive-portal detection (DNS probes, SYN to `192.168.4.1:2050`) but **never gets a
response**, so openNDS never adds it as a client:

- `ndsctl json` → `client_list_length: 0`, `client authentications since start: 0`
- no splash page ever appears on the phone; its browser times out
- the AP works otherwise (WPA2-EAP auth + association OK, DHCP/DNS served)

## 2. Environment facts

- Repo: `/srv/repo/nix-config` (branch `main`); homelab box `192.168.1.3`, SSH `homelab`.
  `/srv/repo/nix-lab` is the archived reference (do not edit).
- AP stack = single toggle `services.ap.enable`; files in `commons/network/ap/`
  (`opennds.nix`, `hostapd.nix`, `dnsmasq.nix`, `freeradius.nix`, `router.nix`, `default.nix`).
- `hostapd` uses `wlp2s0` (192.168.4.1/24); WAN = `enp0s31f6` (192.168.1.3).
- dnsmasq listens on `192.168.4.1:53` (fd 6), `192.168.1.3:53`, `127.0.0.1:53`.
- MHD server (openNDS 11.0.0) listening `0.0.0.0:2050`, pid 1407 (`.opennds-unwrapped`).
- openNDS key config: `gatewayport 2050`, `fwhook_enabled 1`, `dhcp_leases_file
  '/var/lib/dnsmasq/dnsmasq.leases'`, FAS Secure Level 1
  `http://192.168.4.1:2050/opennds_preauth/`, `custombinauth /srv/appdata/opennds/binauth-voucher.sh`,
  `faskey 1234567890`, `checkinterval 15`, debuglevel 3.
- Repo rule: agents NEVER run `sudo nixos-rebuild`; owner runs it.
- `conntrack` CLI is NOT installed on homelab — use `/proc/net/nf_conntrack`.

## 3. Evidence (from live capture + live state, 2026-08-03 ~00:39–00:41)

Capture file on homelab: `/tmp/opencode/phone-trace.pcap` (tcpdump on `wlp2s0`,
filter `host 192.168.4.115`, sudo needed for CAP_NET_RAW).

- **33 SYN packets** from `192.168.4.115` to `192.168.4.1:2050` (multiple source ports,
  TCP retransmits) → **0 SYN-ACKs** from host. TCP handshake never completes.
- **92 DNS queries** from phone (udp/53) → **0 replies** from host to phone.
- Host→phone packets present: **ARP replies** (`192.168.4.1 is-at b8:81:98:42:b4:7c`)
  and **ICMP port-unreachable** (nftables `reject` for the phone's outbound :443 tries).
- `ndsRTR` (input hook, priority -100) counters at time of check:
  - `ct state invalid drop` = 0
  - `tcp dport 2050 accept` = **141 pkts** (SYNs ARE accepted by netfilter)
  - `udp dport 53 accept` = **1851 pkts**
- `ndsOUT` (nat prerouting) `ip daddr 192.168.4.1 tcp dport 2050 accept` = 91 pkts.
- `/proc/net/nf_conntrack` at 00:48 showed only localhost curl entries
  (`src=dst=192.168.4.1:2050`, TIME_WAIT) — **no entries for the phone at all**.
  (Note: checks happened ~7 min after capture; SYN/DNS entries may simply have expired —
  this is NOT conclusive by itself.)
- `ip neigh`: `192.168.4.115 dev wlp2s0 lladdr ea:0a:02:8a:8f:08 STALE` — host knows the MAC.
- `ip route get 192.168.4.115 from 192.168.4.1` → `dev wlp2s0 src 192.168.4.1` — routing is sane.
- `curl http://127.0.0.1:2050/mhdstatus` and `curl http://192.168.4.1:2050/mhdstatus`
  from the homelab itself → **both 200**. MHD works for local delivery.
- rp_filter: `net.ipv4.conf.wlp2s0.rp_filter = 2` (loose), `all = 0`.
- iwlwifi radio: AP interface wlp2s0, client authorized/associated (confirmed via `iw station dump`,
  signal ~ -35 dBm); hostapd fully functional for the phone.

### nftables chain inventory (full dump at `/tmp/opencode/full-ruleset.txt`)

- `nds_filter`: `ndsINP` (input -100), `ndsFWD` (forward -100), `nds_allow_INP` (input srcnat),
  `nds_allow_FWD` (forward 100), `ndsNET`, `ndsRTR`, `ndsAUT`, `ndsULR`, flowtable `ndsftOUT`
  (ingress -100 on wlp2s0, **no flows added**).
- `nds_mangle`: `ndsPRE` (prerouting dstnat), `ndsPOST` (forward -100), `ndsINC`, `nds_ft_INC`,
  flowtable `ndsftINC` (ingress -100 on enp0s31f6, **no flows added**).
- `nds_nat`: `ndsPRE` (prerouting dstnat) → `ndsOUT` (redirect :80→:2050, dnat :80→192.168.4.1:2050,
  `ip daddr 192.168.4.1 tcp dport 2050 accept`, final `accept`).
- iptables-nft (`table ip nat`): `nixos-nat-pre` marks all wlp2s0 ingress with `mark|0x1`;
  `nixos-nat-post` masquerades on `enp0s31f6` egress only when mark&0x1 set (this is the WAN NAT
  for AP clients). Netavark chains only touch podman (10.88.0.0/16) + hostport 9093.

### What the netfilter evidence says

Incoming SYN/DNS from the phone **passes all netfilter hooks** (accepted in input) yet
**no socket-originated reply is transmitted on wlp2s0** — while netfilter-generated replies
(ARP reply, ICMP reject) **are** transmitted and reach the phone. The blocking point is
therefore between "accepted by input hook" and "reply on the wire" — i.e. a kernel/TCP/UDP
stack or driver-level delivery issue, NOT the openNDS client-detection chain
(which is request-driven and never even sees a completed TCP handshake).

## 4. What was RULED OUT (evidence-backed)

- openNDS fwhook not running → NO. openNDS 11.0.0 has no separate fwhook daemon; client
  detection is purely request-driven in `src/http_microhttpd.c` (`libmicrohttpd_cb` →
  `get_interface_by_ip` → `get_client_mac` → `add_client` → `dhcpcheck`). Empty `ndsTRU`/
  `ndsOUT` mangle chains are EXPECTED until clients authenticate. The phone's TCP request
  never completes, so nothing to detect.
- Detection primitives broken → NO. Verified standalone: `libopennds.sh dhcpcheck 192.168.4.115`
  → returns `ea:0a:02:8a:8f:08` rc=0; `get_interface_by_ip` → `wlp2s0` rc=0.
- MHD not listening / crashed → NO. `ss -tnlp` shows `LISTEN 0 4096 0.0.0.0:2050`; local curls 200;
  daemon logs show normal client-list refresh.
- netfilter dropping the SYN/DNS → NO. Counters prove acceptance (141 / 1851).
- Conntrack invalid-drop → NO. `ct state invalid drop` counter = 0.
- rp_filter strict → NO. wlp2s0 = loose(2), and replies to the phone do egress successfully.
- Flowtable offload swallowing replies → UNLIKELY. `ndsftOUT`/`ndsftINC` have zero flows added.
- Phone ARP/MAC unknown → NO. `ip neigh` has lladdr; host TX to phone works (ARP/ICMP).
- Wrong source-address routing of replies → NO. Reply route is `dev wlp2s0 src 192.168.4.1`.
- Missing `/bin/bash` breaking theme spawn / FAS → POSSIBLE CO-SUSPECT for *splash rendering*
  but NOT the cause of "no client registers" (that needs a completed handshake first).
  openNDS scripts still referenced `/bin/bash`; keep in mind but secondary.
- Recurring log `failure: /usr/lib/opennds/libopennds.sh preemptivemac quiet` every refresh →
  BENIGN. Standalone `bash -x` run exits 0 with empty `preemptivemac=`; no Preemptive MACs
  configured, daemon just logs "failure" on empty result.

## 5. LEADING HYPOTHESES (ranked)

1. **Locally-generated (socket) replies to wireless STA are silently not transmitted** —
   TX path for locally-originated TCP/UDP to the STA is broken while netfilter-generated
   packets (ARP/ICMP) work. Look at: iwlwifi/AP-mode TX for unicast data frames; whether the
   STA's association key/TID is in a bad state; `iw dev wlp2s0 station dump` flags;
   try a plain `ping` from homelab → phone (ICMP echo) vs `nc`/curl from homelab → phone.
   (DISCREPANCY: ICMP *unreachable* reached the phone, so plain unicast ICMP echo is the key
   discriminator test — never run it yet.)

2. **SYN/DNS delivered to a different network namespace / container** (podman/netavark
   interference) — the packets are accepted by the inet hooks but land in a netns where no
   socket listens. Weak (MHD is on the host, localhost curl works), but verify with
   `ss -tnlp` in the podman netns and `nsenter`.

3. **Policy routing / fwmark trap** — `ip rule` has fwmark 0x80000/0xff0000 lookups +
   `unreachable` at rule 5250, and openNDS marks use bits 16-17 (0x30000) that overlap the
   mask 0xff0000. If a reply gets mark 0x80000 it becomes unreachable. Verify by checking
   reply packets' fwmark and by temporarily flushing rules 5210-5270.

4. **Hostapd/AP mode quirk with this specific client** (iwlwifi AP + STA data-frame
   delivery): try a second client device; try a plain open (non-EAP) SSID; check
   `hostapd_cli all_sta`, `iw wlp2s0 station dump`, driver logs.

## 6. NEXT STEPS (for the next agent)

1. Re-run a **live bidirectional capture** on `wlp2s0` (no host filter; also mirror to
   `enp0s31f6` and `lo`) while the phone retries the splash. Confirm whether SYN-ACK is
   generated at all and on which interface.
2. Run the **plain-unicast discriminator test**: `ping -I wlp2s0 192.168.4.115` and
   `nc -vz 192.168.4.115 <port>` from homelab → phone. If ping works but TCP/UDP don't,
   hypothesis #1 is confirmed (socket-TX vs netfilter-TX).
3. Check fwmark trap: capture with `-d` and inspect `meta mark`; `nft list ruleset | grep -n fwmark`;
   temporarily `ip rule del` 5250 (unreachable) and re-test.
4. Check netns isolation: `lsns -t net`, `ss -ltn` per netns for 2050.
5. Test with a **second client device** and an **open guest SSID** to rule out a
   phone-specific / EAP-specific path.
6. If hypothesis #1 confirmed at driver level: try `iw dev wlp2s0 set power_save off`,
   check `iwlwifi` firmware logs (`journalctl -k`), and consider `nl80211` AP-mode known
   issues for iwlwifi + this kernel (6.18.36).
7. While at it: fix the `/bin/bash` shebang issue in openNDS scripts if it is still present,
   and keep the preemptivemac-empty "failure" log as benign.

## 7. Files / artifacts

- `/tmp/opencode/phone-trace.pcap` — live capture (on homelab)
- `/tmp/opencode/full-ruleset.txt` — full `nft list ruleset` dump (on homelab)
- `/srv/repo/nix-config/commons/network/ap/*.nix` — AP config
- openNDS 11.0.0 source: `src/http_microhttpd.c`, `src/client_list.c`, `src/auth.c`,
  `src/fw_iptables.c` (in `/nix/store/...-opennds-11.0.0/`) — used to map detection flow
- runtime: `/etc/config/opennds`, `/var/lib/dnsmasq/dnsmasq.leases`,
  `/usr/lib/opennds/libopennds.sh`, `/run/ndscids/`

## 8. Useful invariants / related past notes

- Post-refactor invariant: `commons/ai` and `commons/network` must not mix AI vs Internet
  gateway concerns; toggling a gateway must not require editing the gateway's own files.
- openNDS needs dnsmasq as a hard runtime dependency (reads its leases file).
- Once working: single-use 1-hour voucher login via `binauth-voucher.sh` + custom splash is the
  target flow; stale-splash-after-restart is a known UX wart (fresh `fas` fixes "Login failed").
