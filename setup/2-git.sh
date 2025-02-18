#!/bin/bash

# Function to configure git global settings
configure_git() {
    echo "Configuring Git settings..."
    
    git config --global pull.rebase false
    git config --global user.name "Mohammed Munir"
    git config --global user.email "mohammed.munir@gmail.com"
    git config --global push.default simple
    
    # Set nano as default editor
    if [ -x "$(command -v sudo)" ]; then
        sudo git config --system core.editor nano
    else
        git config --system core.editor nano
    fi
    
    # Uncomment these lines if you want to enable credential caching
    # git config --global credential.helper cache
    # git config --global credential.helper 'cache --timeout=32000'
    
    echo "Git configuration complete"
}

# Function to check if SSH key exists
check_ssh_key() {
    if [ ! -f ~/.ssh/id_ed25519 ]; then
        echo "No SSH key found. Generating new key..."
        ssh-keygen -t ed25519 -C "mohammed.munir@gmail.com"
    else
        echo "SSH key already exists"
    fi
}

# Function to start SSH agent and add key
setup_ssh_agent() {
    echo "Starting SSH agent..."
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519
    echo "SSH key added to agent"
    
    echo -e "\nHere's your public SSH key. Add it to GitHub if you haven't already:"
    cat ~/.ssh/id_ed25519.pub
    echo -e "\nGo to GitHub -> Settings -> SSH Keys -> New SSH Key to add this key"
    read -p "Press Enter once you've added the key to GitHub..."
}

# Function to set up Git repository
setup_git_repo() {
    read -p "Enter the local folder path: " local_path
    read -p "Enter the GitHub repository name: " repo_name

    # Change to the directory
    cd "$local_path" || exit

    # Initialize git if not already initialized
    if [ ! -d .git ]; then
        git init
        echo "Git repository initialized"
    fi

    # Set up remote
    git remote remove origin 2>/dev/null
    git remote add origin "git@github.com:mohammedmunir/$repo_name.git"
    echo "Remote origin added"

    # Add and commit files
    git add .
    git commit -m "Initial commit"

    # Rename current branch to main
    git branch -M main

    # Push to GitHub
    echo "Attempting to push to GitHub..."
    git push -u origin main
}

# Main script
echo "GitHub Repository Setup Script"
echo "----------------------------"

# Run functions
configure_git
check_ssh_key
setup_ssh_agent
setup_git_repo

echo "Setup complete!"
