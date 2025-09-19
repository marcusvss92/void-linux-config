#!/bin/bash
# Clean up sandbox user environment

SANDBOX_USER="sandbox"
SANDBOX_HOME="/home/$SANDBOX_USER"

echo "=== Cleaning Sandbox Environment ==="

# Kill all processes from sandbox user
pkill -u $SANDBOX_USER

# Clean home directory but preserve structure
doas -u $SANDBOX_USER find "$SANDBOX_HOME" -type f -delete 2>/dev/null
doas -u $SANDBOX_USER mkdir -p "$SANDBOX_HOME"/{tmp,test,downloads}

# Reset bash history
doas -u $SANDBOX_USER rm -f "$SANDBOX_HOME/.bash_history"
doas -u $SANDBOX_USER rm -f "$SANDBOX_HOME/.zsh_history"

# Clear temporary files
rm -rf /tmp/sandbox-* 2>/dev/null

echo "✅ Sandbox environment cleaned"
