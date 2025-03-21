#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script as root or with sudo."
    exit 1
fi

echo "Updating package list..."
dnf update -y

echo "Installing QEMU, KVM, and virtualization packages..."
dnf install -y @virtualization

echo "Enabling and starting libvirtd service..."
systemctl enable --now libvirtd

echo "Adding current user to the libvirt group..."
usermod -aG libvirt $(logname)

echo "Installing Virt-Manager for GUI support..."
dnf install -y virt-manager

echo "Installation complete! Restart your session or run 'newgrp libvirt' to apply group changes."
echo "You can start Virt-Manager with the command: virt-manager"
