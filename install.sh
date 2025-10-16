#!/bin/bash

# Exit on error
set -e

# Directory to store binary
INSTALL_DIR="$HOME/bin"

DIR_NAME="Z01_cfg"

# Ensure directory exists
mkdir -p "$INSTALL_DIR"

# Download binary
echo "Downloading config-maker..."
curl -Lo "$INSTALL_DIR/$DIR_NAME" https://github.com/AmineS530/zone01-config/releases/download/v1.0/config-maker-linux-amd64

# Make executable
chmod +x "$INSTALL_DIR/$DIR_NAME"

# Add to PATH if not already
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "Adding $INSTALL_DIR to PATH in ~/.bashrc..."
    echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
fi

# Run immediately
echo "Launching configurer..."
"$INSTALL_DIR/$DIR_NAME"
