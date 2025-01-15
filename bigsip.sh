#!/bin/bash
sudo pacman -Syu --noconfirm
yay -Sc --noconfirm
yay -Yc --noconfirm
yay --aur --cleanafter --noconfirm
paccache -rk1 -ruk0
paccache -rk0
