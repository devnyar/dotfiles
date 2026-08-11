#!/bin/sh
# Reinstall the Tailscale LAN-bypass helper, systemd unit, and sudoers rule.
# Managed by chezmoi (run_onchange_): re-runs whenever this script's content changes.
#
# Purpose: the `adguard` tailnet node advertises the home LAN subnet (192.168.1.0/24),
# and this host runs with --accept-routes, which hairpins LAN traffic through the tunnel
# and breaks LocalSend. A pref-5200 ip rule prefers directly-connected routes instead.
# Every `tailscale up` / profile switch rebuilds Tailscale's rules and wipes it, so the
# thome/twork aliases re-apply the helper via passwordless sudo (the sudoers rule below).
set -eu

HELPER=/usr/local/bin/tailscale-lan-bypass
UNIT=/etc/systemd/system/tailscale-lan-bypass.service
SUDOERS=/etc/sudoers.d/tailscale-lan-bypass

# 1. Idempotent bypass helper (v4 + v6).
sudo tee "$HELPER" >/dev/null <<'EOF'
#!/bin/sh
# Prefer directly-connected LAN routes over Tailscale subnet routes.
# Idempotent: delete-then-add avoids duplicate rules.
ip rule del pref 5200 2>/dev/null
ip rule add pref 5200 lookup main suppress_prefixlength 0
ip -6 rule del pref 5200 2>/dev/null
ip -6 rule add pref 5200 lookup main suppress_prefixlength 0
exit 0
EOF
sudo chmod 755 "$HELPER"

# 2. Boot-time systemd unit (applies the rule once at startup).
sudo tee "$UNIT" >/dev/null <<'EOF'
[Unit]
Description=Prefer directly-connected LAN routes over Tailscale subnet routes
After=tailscaled.service
Wants=tailscaled.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/tailscale-lan-bypass
ExecStop=/usr/bin/sh -c 'ip rule del pref 5200 2>/dev/null; ip -6 rule del pref 5200 2>/dev/null; exit 0'

[Install]
WantedBy=multi-user.target
EOF
sudo chmod 644 "$UNIT"

# 3. Passwordless sudo for exactly the helper (validate before installing).
tmp=$(mktemp)
cat >"$tmp" <<'EOF'
banyar ALL=(root) NOPASSWD: /usr/local/bin/tailscale-lan-bypass
EOF
sudo visudo -cf "$tmp" >/dev/null
sudo install -m 440 -o root -g root "$tmp" "$SUDOERS"
rm -f "$tmp"

# 4. Enable + (re)start.
sudo systemctl daemon-reload
sudo systemctl enable --now tailscale-lan-bypass.service

echo "tailscale-lan-bypass: installed and active"
