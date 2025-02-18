# Create fonts directory if it doesn't exist
mkdir -p ~/.local/share/fonts

# Download and install MesloLGS Nerd Font
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Meslo.zip
unzip Meslo.zip -d ~/.local/share/fonts/
fc-cache -fv
# Create fonts directory if it doesn't exist
mkdir -p ~/.local/share/fonts

# Download and install MesloLGS Nerd Font
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Meslo.zip
unzip Meslo.zip -d ~/.local/share/fonts/
fc-cache -fv
