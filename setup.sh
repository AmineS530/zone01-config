image_path="$HOME/zone01-config/Background.jpeg"
# theme list ls -d /usr/share/themes/* |xargs -L 1 basename
theme_color='Yaru-viridian-dark'
git clone https://github.com/AmineS530/zone01-config.git ~/zone01-config && cd ~/zone01-config/ && mv .p10k.zsh ~/.p10k.zsh && mv .zshrc ~/.zshrc
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
zsh git_setup.sh
gsettings set org.gnome.desktop.background picture-uri-dark "file://${image_path}"
gsettings set org.gnome.desktop.background picture-uri "file://${image_path}"
gsettings set org.gnome.desktop.interface gtk-theme $theme_color
