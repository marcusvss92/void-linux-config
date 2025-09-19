#!/bin/bash
# Basic Void Linux post-installation setup

set -e

echo "=== Void Linux Basic Setup ==="

# Update system
echo "Updating system packages..."
doas xbps-install -Su

# Install essential packages
echo "Installing essential packages..."
doas xbps-install -S \
    curl wget git nano htop tree \
    unzip zip p7zip \
    NetworkManager \
    firefox \
    file-roller

# Enable services
echo "Enabling essential services..."
doas ln -sf /etc/sv/NetworkManager /var/service/
doas ln -sf /etc/sv/dbus /var/service/

# Configure git
read -p "Enter your git username: " git_username
read -p "Enter your git email: " git_email

git config --global user.name "$git_username"
git config --global user.email "$git_email"

# Set timezone
echo "Available timezones:"
find /usr/share/zoneinfo -name "*" -type f | grep -E "(America|Europe|Asia)" | head -20
read -p "Enter timezone (e.g., America/New_York): " timezone

if [[ -f "/usr/share/zoneinfo/$timezone" ]]; then
    doas ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
    echo "Timezone set to $timezone"
else
    echo "Invalid timezone, using UTC"
    doas ln -sf /usr/share/zoneinfo/UTC /etc/localtime
fi

# Create user directories
mkdir -p ~/Desktop ~/Documents ~/Downloads ~/Pictures ~/Videos ~/Music

echo "✅ Basic setup completed!"
echo "Next steps:"
echo "1. Run hardening setup: ./scripts/hardening/full-hardening.sh"
echo "2. Setup development environment: ./scripts/install/setup-development.sh"
echo "3. Install pentesting tools: ./scripts/install/setup-pentesting-environment.sh"
