#!/bin/bash

# Quick Start Script for k3s Security Hardening

set -e

echo "=========================================="
echo "k3s Security Hardening - Quick Start"
echo "=========================================="
echo ""

# Check if Ansible is installed
if ! command -v ansible &> /dev/null; then
    echo "❌ Ansible is not installed."
    echo "Installing Ansible..."
    sudo apt update
    sudo apt install -y ansible
fi

echo "✅ Ansible is installed"
echo ""

# Check if inventory file exists and is configured
if [ ! -f "inventory.ini" ]; then
    echo "❌ inventory.ini not found!"
    exit 1
fi

if grep -q "YOUR_MASTER_IP\|YOUR_WORKER_IP" inventory.ini; then
    echo "⚠️  WARNING: Please update inventory.ini with your actual server IPs!"
    echo "   Edit inventory.ini and replace YOUR_MASTER_IP and YOUR_WORKER_IP"
    exit 1
fi

echo "✅ Inventory file configured"
echo ""

# Install Ansible collections
echo "Installing Ansible collections..."
ansible-galaxy collection install -r requirements.txt
echo "✅ Collections installed"
echo ""

# Test connectivity
echo "Testing connectivity to servers..."
if ansible all -m ping; then
    echo "✅ All servers are reachable"
else
    echo "❌ Cannot reach one or more servers. Please check:"
    echo "   - SSH access is configured"
    echo "   - IP addresses in inventory.ini are correct"
    echo "   - SSH keys are set up (or password authentication is enabled)"
    exit 1
fi

echo ""
echo "=========================================="
echo "Ready to run security hardening!"
echo "=========================================="
echo ""
echo "⚠️  IMPORTANT WARNINGS:"
echo "   1. This will disable password authentication (SSH keys only)"
echo "   2. This will disable root login via SSH"
echo "   3. This will enable UFW firewall"
echo "   4. Make sure you have console access as backup!"
echo ""
read -p "Do you want to proceed? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "Running security hardening playbook..."
ansible-playbook security-hardening.yml

echo ""
echo "=========================================="
echo "Security hardening complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Verify SSH access still works with your SSH key"
echo "2. Check firewall: sudo ufw status verbose"
echo "3. Check Fail2ban: sudo fail2ban-client status"
echo "4. Verify k3s cluster connectivity"
echo ""

