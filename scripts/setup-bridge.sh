#!/bin/bash

# Define bridge and interface variables
BRIDGE="br0"
ETH_IFACE="enp0s20f0u1u4"
STATIC_IP="10.0.1.200/24"

echo "Setting up network bridge: $BRIDGE"

# Check if the bridge already exists
if nmcli connection show "$BRIDGE" &>/dev/null; then
    echo "Bridge $BRIDGE already exists. Deleting it..."
    sudo nmcli connection delete "$BRIDGE"
fi

# Add the bridge and assign a static IP
sudo nmcli connection add type bridge autoconnect yes con-name "$BRIDGE" ifname "$BRIDGE"
sudo nmcli connection modify "$BRIDGE" ipv4.addresses "$STATIC_IP" ipv4.method manual

# Attach the Ethernet interface to the bridge
sudo nmcli connection add type ethernet slave-type bridge autoconnect yes con-name "${ETH_IFACE}-br" ifname "$ETH_IFACE" master "$BRIDGE"

# Bring up the bridge
sudo nmcli connection up "$BRIDGE"

echo "Bridge setup complete!"

