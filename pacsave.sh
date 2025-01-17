#!/bin/bash
pacman -Qem | awk '{print $1}' > excludes.txt
declare -a exclude
while IFS= read -r line; do
  exclude+=("$line")
done < excludes.txt
for pkg in $(pacman -Q | awk '{print $1}'); do
  if [[ ! " ${exclude[@]} " =~ " $pkg " ]]; then
    echo "$pkg" >> paclist.txt
  fi
done
