#!/bin/bash
# File: 1-setup-podman.sh
# Description: Install Podman and make it behave like Docker

echo "📦 Installing Podman (Docker-compatible container engine)..."

sudo dnf install -y \
    podman \
    podman-docker \
    buildah \
    skopeo \
    fuse-overlayfs \
    slirp4netns

# Optional: Set up rootless containers better
echo "Enabling rootless mode..."
sudo sysctl kernel.unprivileged_userns_clone=1
echo 'kernel.unprivileged_userns_clone=1' | sudo tee -a /etc/sysctl.conf

# Enable Docker alias
if ! grep -q "alias docker=podman" ~/.bashrc; then
    echo 'alias docker=podman' >> ~/.bashrc
    echo "✅ Added 'docker' alias to ~/.bashrc"
fi

# Reload shell config
source ~/.bashrc

echo "✅ Podman installed! You can now use 'docker' commands."
echo "💡 Try: docker --version"