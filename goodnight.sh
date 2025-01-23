#!/bin/bash
veracrypt -d
if [[ $? -eq 0 ]]; then
  #paplay ~/Music/file.wav &
  sudo pacman -Syuv --noconfirm && \
  sudo pacman -Scv --noconfirm && \
  yay -Yc --noconfirm && \
  yay -a --noconfirm && \
  echo 'Goodnight!'
else
  echo "VeraCrypt failed to dismount. Script halted."
fi
