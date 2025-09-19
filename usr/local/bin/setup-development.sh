#!/bin/bash
# Development environment setup

set -e

echo "=== Development Environment Setup ==="

# Programming languages and tools
echo "Installing development tools..."
doas xbps-install -S \
    gcc make cmake \
    python3 python3-pip python3-devel \
    nodejs npm \
    rust cargo \
    go \
    docker docker-compose \
    sqlite \
    postgresql postgresql-contrib

# Enable Docker
doas ln -sf /etc/sv/docker /var/service/
doas usermod -aG docker $USER

# Python tools
echo "Installing Python development tools..."
pip3 install --user \
    virtualenv \
    pipenv \
    black \
    flake8 \
    pytest

# Node.js global tools
echo "Installing Node.js development tools..."
npm install -g \
    typescript \
    eslint \
    prettier \
    nodemon

# Create development directories
mkdir -p ~/Development/{python,javascript,rust,go,docker}

# Configure PostgreSQL
echo "Configuring PostgreSQL..."
doas ln -sf /etc/sv/postgresql /var/service/
sleep 3
doas -u postgres createuser -s $USER 2>/dev/null || true

echo "✅ Development environment ready!"
echo "Restart terminal to apply Docker group changes"
