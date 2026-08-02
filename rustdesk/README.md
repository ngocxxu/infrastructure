# RustDesk Server — Native Install (no Docker)

Self-hosted RustDesk server (`hbbs` + `hbbr`) installed directly on a VPS via
systemd. No Docker, no Kubernetes — this is a lightweight, two-process
service, and native install keeps RAM usage minimal (a few tens of MB).

## What's included

| File                    | Purpose                                              |
| ------------------------ | ----------------------------------------------------- |
| `install-rustdesk.sh`   | Downloads, installs, and starts hbbs + hbbr as systemd services |
| `uninstall-rustdesk.sh` | Cleanly removes everything the installer created      |

## Requirements

- A Linux VPS (Ubuntu/Debian recommended; script uses `apt-get` for `unzip` if missing)
- `x86_64` or `aarch64`/`armv7` architecture (auto-detected)
- A user account with **sudo** access (does not need to be `root` itself)
- Outbound internet access (to download the release from GitHub)

Check you have sudo before starting:

```bash
sudo -l
```

If that errors with "not in sudoers", ask whoever holds root to run:

```bash
usermod -aG sudo your_username
```

then log out and back in.

## Install

1. Copy both scripts to the VPS:

   ```bash
   cd rustdesk/
   scp install-rustdesk.sh uninstall-rustdesk.sh user@your-vps-ip:~/
   ```

2. SSH in and run the installer:

   ```bash
   ssh user@your-vps-ip
   chmod +x install-rustdesk.sh uninstall-rustdesk.sh
   sudo ./install-rustdesk.sh
   ```

   Optionally pass the public IP explicitly if auto-detection picks the wrong
   one (e.g. behind NAT with multiple interfaces):

   ```bash
   sudo ./install-rustdesk.sh 203.0.113.10
   ```

3. At the end, the script prints the **public key** — copy it into the
   RustDesk client's server settings (`ID Server`, `Relay Server`, `Key`).

### What the installer does

- Creates a dedicated, login-disabled system user `rustdesk` — the service
  never runs as your personal account or as root.
- Installs binaries to `/opt/rustdesk/bin`.
- Stores runtime data (keys, ID database) in `/var/lib/rustdesk`.
- Stores logs in `/var/log/rustdesk`.
- Registers two systemd units: `rustdesk-hbbs.service` and
  `rustdesk-hbbr.service`, both set to auto-restart on failure.
- Opens the required ports in `ufw` if it's active (see Ports below).

## Ports

| Port         | Protocol | Used by     |
| ------------ | -------- | ----------- |
| 21115        | TCP      | hbbs (NAT type test) |
| 21116        | TCP + UDP| hbbs (ID/heartbeat) |
| 21117        | TCP      | hbbr (relay) |
| 21118        | TCP      | hbbs (web client, optional) |
| 21119        | TCP      | hbbr (web client, optional) |

The installer opens these in `ufw`. If your VPS provider has a **separate
firewall/security group layer** outside the OS (common on enterprise cloud
panels, less common on small/cheap VPS resellers), open the same ports there
too — otherwise traffic gets dropped before it reaches `ufw`.

Verify after install:

```bash
# Locally on the VPS — confirms the services are listening
ss -tulnp | grep -E '211(15|16|17|18|19)'

# From another machine — confirms the ports are actually reachable
nc -zv your-vps-ip 21115-21119
```

If `ss` shows the ports listening but `nc` from outside fails, the block is
happening upstream (provider firewall, anti-DDoS filtering on uncommon
ports) — contact your VPS provider's support to whitelist the ports.

## Connect a client

Once the services are running and ports are verified (see above), point your
RustDesk clients at your own server instead of the public RustDesk relay.

1. Install the RustDesk **client** (not the server) on both the controlling
   machine and the machine to be controlled — download from rustdesk.com or
   the GitHub releases page.

2. Get the public key from the VPS if you don't have it from the install output:

   ```bash
   cat /var/lib/rustdesk/id_ed25519.pub
   ```

3. On **both** machines: open the client → gear icon → **Network** →
   "Unlock Network Settings" (may prompt for the local password) → fill in:

   - **ID Server**: your VPS's public IP (or domain, see Cloudflare note below)
   - **Relay Server**: same as ID Server
   - **Key**: paste the public key from step 2

   Click Apply. Status should switch to "Ready" once both machines are
   pointed at the same server.

4. On the machine to be controlled, RustDesk shows an ID + a temporary
   password. Enter that ID on the controlling machine, click Connect, enter
   the password.

For daily use, set a fixed password on the controlled machine (Settings →
Security) instead of relying on the rotating temporary one.

### Using a domain behind Cloudflare

If you're pointing a Cloudflare-managed domain at the VPS instead of using
the raw IP: Cloudflare's proxy (orange cloud) only forwards HTTP/HTTPS on
ports 80/443. RustDesk uses raw TCP/UDP on 21115-21119, which the proxy
doesn't forward (Cloudflare's TCP/UDP proxy, Spectrum, is a paid
enterprise feature). Set the DNS record to **DNS only** (grey cloud) so it
resolves directly to the VPS IP.

Note this isn't a security downgrade — DNS-only still resolves to the real
IP just like using the IP directly, and RustDesk's actual security comes
from the key-based encryption between client and server, not from hiding
the IP. Using the raw IP with no domain at all is equally safe; a domain
just makes it easier to repoint later if the VPS IP ever changes.

## macOS: keep a controlled Mac reachable (don't let it fully sleep)

RustDesk (like most remote-desktop tools) can wake a Mac's **display** if the
Mac itself is still running, but it **cannot wake a Mac from full system
sleep** — once macOS suspends the whole system, its network stack stops
responding and RustDesk has no way to signal it back awake. This is a known
RustDesk limitation (see [rustdesk/rustdesk#981](https://github.com/rustdesk/rustdesk/issues/981)),
not a misconfiguration.

The fix is to make sure the Mac only ever sleeps its **display**, never the
whole system, while you might need to reach it remotely:

1. **System Settings → Displays → Advanced** → enable **"Prevent automatic
   sleeping when the display is off"** (macOS Ventura and later; on older
   versions this lives in the Energy Saver pane).
2. **System Settings → Battery → Options** → enable **"Wake for network
   access"**.
3. Keep the Mac plugged into power — these settings are only reliable on AC
   power, laptops running on battery will still force deeper sleep.
4. Never close a MacBook's lid — that forces real system sleep regardless of
   the settings above (unless using clamshell mode with an external display
   and power connected).

### Terminal alternative (pmset)

To disable system sleep while on AC power:

```bash
sudo pmset -c disablesleep 1
```

To re-enable normal sleep behavior when you no longer need always-on remote
access:

```bash
sudo pmset -c disablesleep 0
```

(`-c` scopes this to "on charger/AC power" only; the Mac will still sleep
normally on battery. Use `-a` instead of `-c` to apply to both AC and
battery if the Mac never runs unplugged.)

Trade-off: disabling sleep keeps the Mac drawing power continuously so it's
always reachable — fine for a Mac that's normally plugged in anyway, wasteful
for one you actually want to save power on when not in use.

## Manage the service

```bash
systemctl status rustdesk-hbbs rustdesk-hbbr
systemctl restart rustdesk-hbbs rustdesk-hbbr
journalctl -u rustdesk-hbbs -f          # live logs
tail -f /var/log/rustdesk/hbbs.log      # or via the log file directly
```

## Uninstall

```bash
sudo ./uninstall-rustdesk.sh              # removes everything, including keys/ID database
sudo ./uninstall-rustdesk.sh --keep-data  # keeps /var/lib/rustdesk so re-installing preserves the same server ID
```

This stops and disables both services, removes the systemd unit files,
deletes `/opt/rustdesk`, `/var/log/rustdesk`, the `rustdesk` system user, and
the related `ufw` rules.

## Troubleshooting

- **`curl: (23) Failure writing output to destination` during install**
  (while looking up the latest release): fixed in the current version of
  `install-rustdesk.sh`. The earlier version piped `curl` directly into
  `grep -m1`, which closes the pipe as soon as it finds a match — `curl`
  gets cut off mid-write and errors out. The script now captures the full
  API response before parsing it. If you hit this, just re-run
  `sudo ./install-rustdesk.sh` with the updated script; it's safe to re-run.
- **Ports listening locally but unreachable from outside**: run
  `ss -tulnp | grep -E '211(15|16|17|18|19)'` on the VPS to confirm the
  services are actually listening, then `nc -zv your-vps-ip 21115-21119`
  from another machine. If the first succeeds and the second fails, the
  block is upstream — the VPS provider's firewall/security group, or
  anti-DDoS filtering on uncommon ports. Contact their support to whitelist
  21115-21119/tcp and 21116/udp.
- **Client can't reach the server after switching to a custom Key/ID
  Server**: double-check the exact same IP/domain and key are set on both
  the controlling and controlled machine — a mismatch on either side keeps
  them on the public RustDesk relay instead of your own.

## Notes

- **Why native instead of Docker/Kubernetes:** hbbs/hbbr is a 2-process,
  always-on workload with no scaling or orchestration needs. Docker adds
  ~50-100MB overhead for the daemon alone; Kubernetes adds far more (control
  plane, kubelet) and complicates exposing fixed UDP/TCP ports via
  `hostNetwork`. On a small VPS, native + systemd is the leanest option.
- **RAM:** hbbs + hbbr together typically use well under 100MB at idle —
  fine even on a 1-2GB VPS.
- **Re-running the installer** is safe; it re-downloads the latest release
  and overwrites the binaries, but leaves existing data/keys untouched.
