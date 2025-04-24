#!/bin/bash
veracrypt -d
if [[ $? -eq 0 ]]; then
  #pw-play ~/Music/file.wav &
  sudo pacman -Syuv --noconfirm && \
  sudo pacman -Scv --noconfirm && \
  yay -Yc --noconfirm && \
  yay -a --noconfirm && \
  echo 'Goodnight!'
  shutdown now
else
  echo "VeraCrypt failed to dismount. Script halted."
fi
