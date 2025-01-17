#!/bin/zsh

image_path="$HOME/zone01-config/wallpapers/Background.jpeg"

# theme list ls -d /usr/share/themes/* |xargs -L 1 basename

# Makes you use french and english layouts
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'fr')]" > /dev/null 2>&1

# Set logout when idle to 1.5 hour
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 5400 >/dev/null 2>&1

#Move the premade p10k settings and zshrc
mv .p10k.zsh ~/.p10k.zsh && mv .zshrc ~/.zshrc

# clones zsh theme 
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k

# small script to set up git for first use and to rembember your info in the future
zsh git_setup.sh

# changing the background
gsettings set org.gnome.desktop.background picture-uri-dark "file://${image_path}" 2>/dev/null
gsettings set org.gnome.desktop.background picture-uri "file://${image_path}" 2>/dev/null

# Changes theme Color
zsh set_theme.sh

# change display and terminal font
zsh set_font.sh

# forward to zsh whenever termenal auto-start bash
printf "SHELL=/bin/zsh\nexec /bin/zsh -l\n" >> ~/.bashrc
