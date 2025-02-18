#!/bin/bash
# ----------------------------------------------------- 

selected=$(ls -1 ~/dotfiles/myMenu  | rofi -dmenu -p "mymenu" -i)


if [ "$selected" ]; then

    echo "menu selected..."
    echo $selected
    exec "~/dotfiles/myMenu/$selected"
    echo "Done."
fi
