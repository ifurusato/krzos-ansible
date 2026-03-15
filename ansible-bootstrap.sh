#!/bin/bash
set -e
echo "=== Bootstrapping Raspberry Pi for Ansible ==="
# Ensure we are root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo)"
    exit 1
fi
echo "Updating apt cache..."
apt update
echo "Installing Python 3 and required packages for Ansible..."
apt install -y python3 python3-pip python3-venv python3-six
echo "Bootstrap complete. Ansible can now run on this Pi."
