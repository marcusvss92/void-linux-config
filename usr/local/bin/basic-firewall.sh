#!/bin/bash
# Basic firewall script using nftables

# Flush old rules
nft flush ruleset

# Create a table 'inet filter' (works with IPv4 and IPv6)
nft add table inet filter

# Create chains with standard policies
nft 'add chain inet filter input { type filter hook input priority 0; policy drop; }'
nft 'add chain inet filter forward { type filter hook forward priority 0; policy drop; }'
nft 'add chain inet filter output { type filter hook output priority 0; policy accept; }'

# Allow local network traffic (loopback)
nft add rule inet filter input iif lo accept

# Allow established and related connections
nft add rule inet filter input ct state established,related accept

# Allow ICMP echo-request (ping)
nft add rule inet filter input icmp type echo-request accept

# Additional rule example (uncomment to allow SSH)
# nft add rule inet filter input tcp dport 22 accept

# Save rules (adjust accordingly to your distro)
# OpenBSD/FreeBSD example with doas + manual persistence:
# nft list ruleset > /etc/nftables.conf
