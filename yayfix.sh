#!/bin/bash
echo "Are you installing on the Steam Deck? [yes/no]"
read -r answer
case "$answer" in
  "yes" | "y")
    cd /tmp && \
    git clone 'https://aur.archlinux.org/yay-bin.git' && \
    cd /tmp/yay-bin && \
    git checkout 96f90180a3cf72673b1769c23e2c74edb0293a9f
    makepkg -si && \
    cd ~ && \
    rm -rf /tmp/yay-bin
    ;;
  "no" | "n")
    cd /tmp && \
    git clone 'https://aur.archlinux.org/yay.git' && \
    cd /tmp/yay && \
    makepkg -si && \
    cd ~ && \
    rm -rf /tmp/yay
    ;;
  *)
    echo "Invalid input."
    exit 1
    ;;
esac
