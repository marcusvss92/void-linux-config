#!/bin/bash
# Complete system hardening script

set -e

echo "=== Void Linux Full Hardening ==="

# Kernel hardening
echo "Applying kernel hardening..."
./kernel-hardening.sh

# Configure doas
echo "Setting up doas..."
./setup-doas.sh

# Network hardening
echo "Applying network hardening..."
doas cp ../configs/sysctl/99-security.conf /etc/sysctl.d/
doas sysctl -p /etc/sysctl.d/99-security.conf

# File system hardening
echo "Hardening file system..."
doas chmod 600 /etc/shadow
doas chmod 600 /etc/gshadow
doas chmod 644 /etc/passwd
doas chmod 644 /etc/group

# Set restrictive umask
echo "umask 027" | doas tee -a /etc/profile

# Configure audit system
echo "Setting up audit system..."
doas xbps-install -S audit
doas ln -sf /etc/sv/auditd /var/service/

# Basic audit rules
doas tee /etc/audit/rules.d/audit.rules << 'EOF'
# Monitor important files
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/doas.conf -p wa -k actions
-w /var/log/faillog -p wa -k logins
-w /var/log/lastlog -p wa -k logins
EOF

# Configure fail2ban
echo "Setting up fail2ban..."
doas xbps-install -S fail2ban
doas ln -sf /etc/sv/fail2ban /var/service/

# Basic SSH protection
doas tee /etc/fail2ban/jail.local << 'EOF'
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime = 3600
EOF

# Setup integrity monitoring
echo "Setting up AIDE..."
doas xbps-install -S aide
doas aide --init
doas mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz

# Create daily check
echo '0 3 * * * root /usr/bin/aide --check' | doas tee -a /etc/crontab

# Secure shared memory
echo "Securing shared memory..."
echo 'tmpfs /run/shm tmpfs defaults,nodev,nosuid,noexec 0 0' | doas tee -a /etc/fstab

# Configure firewall (basic iptables)
echo "Setting up basic firewall..."
doas tee /usr/local/bin/basic-firewall.sh << 'EOF'
#!/bin/bash
# Basic firewall script using nftables

# Flush old rules
nft flush ruleset

# Create a table 'inet filter' (work for IPv4 and IPv6)
nft add table inet filter

# Create standard policies chains
nft 'add chain inet filter input { type filter hook input priority 0; policy drop; }'
nft 'add chain inet filter forward { type filter hook forward priority 0; policy drop; }'
nft 'add chain inet filter output { type filter hook output priority 0; policy accept; }'

# Allow local network traffic (loopback)
nft add rule inet filter input iif lo accept

# Allow established connections or related
nft add rule inet filter input ct state established,related accept

# Allow ICMP echo-request (ping)
nft add rule inet filter input icmp type echo-request accept

# Additional rule's example (uncomment to apply SSH connections)
# nft add rule inet filter input tcp dport 22 accept

# Save rules (adjust with your own distro)
# OpenBSD/FreeBSD with doas + manual persistence configuration:
# nft list ruleset > /etc/nftables.conf
EOF

doas chmod +x /usr/local/bin/basic-firewall.sh

echo "✅ Full hardening completed!"
echo ""
echo "Applied hardening:"
echo "- Kernel security parameters"
echo "- Restrictive file permissions"  
echo "- Network security settings"
echo "- Audit system with monitoring"
echo "- Fail2ban for intrusion prevention"
echo "- AIDE for integrity monitoring"
echo "- Basic firewall framework"
echo ""
echo "Remember to:"
echo "1. Configure SSH properly"
echo "2. Set up specific firewall rules"
echo "3. Test all functionality"
echo "4. Review audit logs regularly"
