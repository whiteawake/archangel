#!/bin/bash
sudo pacman -S --needed git base-devel && \
git clone https://aur.archlinux.org/yay.git && \
cd yay && \
makepkg -si && \
yay -Y --gendb && \
yay -a --devel=false --noconfirm --rebuildall --removemake --answerclean Installed --answerdiff None --cleanafter --save
yay -Pg
