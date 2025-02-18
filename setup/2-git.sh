#!/bin/bash
# ------------------------------------------------------
# setup Git user details
# ------------------------------------------------------
sudo pacman -S --noconfirm --needed git

project=$(basename `pwd`)
echo "-----------------------------------------------------------------------------"
echo "this is project https://github.com/mohammedmunir/"$project
echo "-----------------------------------------------------------------------------"
git config --global pull.rebase false
git config --global user.name "Mohammed Munir"
git config --global user.email "mohammed.munir@gmail.com"
sudo git config --system core.editor nano
#git config --global credential.helper cache
#git config --global credential.helper 'cache --timeout=32000'
git config --global push.default simple

git remote set-url origin git@github.com-arch:mohammedmunir/$project


# ------------------------------------------------------
# setup SSH Multi
# ------------------------------------------------------
ssh-keygen -t rsa -C "mohammed.munir@gmail.com"
ssh-keygen -t rsa -f ~/.ssh/arch -C "mohammed.munir@gmail.com"

#touch ~/.ssh/config

# ------------------------------------------------------
# Setup Multi SSH file
# ------------------------------------------------------
echo "Host github.com-arch" > ~/.ssh/config
echo -e "\tHostname github.com" >> ~/.ssh/config
echo -e "\tidentityFile=~/.ssh/arch" >> ~/.ssh/config



echo "Everything set"

echo "################################################################"
echo "###################    T H E   E N D      ######################"
echo "################################################################"
