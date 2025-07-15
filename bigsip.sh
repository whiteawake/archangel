#!/bin/bash
sudo pacman -Syuv --noconfirm
yay -Yc --noconfirm && yay -Sua --noconfirm
paccache -rk1 && paccache -ruk0