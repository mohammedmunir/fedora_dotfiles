#!/bin/bash

# Function to configure DNF
configure_dnf() {
    echo "Configuring DNF..."
    sudo tee -a /etc/dnf/dnf.conf > /dev/null <<EOL
# Custom DNF configuration
max_parallel_downloads=10
fastestmirror=1
assumeyes=True
EOL
}

# Function to update system and firmware
update_system() {
    echo "Updating system..."
    sudo dnf update -y
}

update_firmware() {
    echo "Updating firmware..."
    sudo fwupdmgr refresh --force
    sudo fwupdmgr get-updates
    sudo fwupdmgr update
}

# Function to install DNF5
install_dnf5() {
    echo "Installing DNF5..."
    sudo dnf install -y dnf5 dnf5-plugins
}

# Function to add RPM Fusion repositories
enable_rpm_fusion() {
    echo "Enabling RPM Fusion repositories..."
    sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf upgrade --refresh -y
}

# Function to install GNOME Tweaks and Extensions Manager
install_gnome_tools() {
    echo "Installing GNOME Tweaks and Extensions Manager..."
    sudo dnf5 install -y gnome-tweaks
    flatpak install -y flathub com.mattjakeman.ExtensionManager
}

# Function to install essential packages
install_essential_packages() {
    echo "Installing essential packages..."
    sudo dnf5 install -y fastfetch mpv wget git gcc make python3 python3-pip unrar unzip cargo p7zip p7zip-plugins ntfs-3g htop java-17-openjdk android-tools vlc remmina
}

# Function to install useful GUI applications
install_gui_apps() {
    echo "Installing useful GUI applications..."
    flatpak install -y flathub io.missioncenter.MissionCenter
}

# Main function to run all tasks
main() {
    configure_dnf
    update_system
    update_firmware
    install_dnf5
    enable_rpm_fusion
    install_gnome_tools
    install_essential_packages
    install_gui_apps
    echo "All tasks completed. Rebooting the system..."
    sudo reboot
}

# Run the main function
main
