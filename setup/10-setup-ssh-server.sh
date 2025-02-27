#!/bin/bash

# Enable and start SSH
sudo systemctl enable --now sshd

# Display IP Address
ip -4 addr show | grep -oP '(?<=inet\s)\d+\.\d+\.\d+\.\d+'

# Install TigerVNC server
sudo dnf install -y tigervnc-server

# Create VNC user mapping
echo ":1=$(whoami)" | sudo tee /etc/tigervnc/vncserver.users

# Set VNC password (User will need to enter it)
echo "Set your VNC password:"
vncpasswd

# Reload systemd daemon
sudo systemctl daemon-reload

# Restart VNC server
sudo systemctl restart vncserver@:1

# Enable VNC server at boot
sudo systemctl enable vncserver@:1

# Check VNC server status
systemctl status vncserver@:1

