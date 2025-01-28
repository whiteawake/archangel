#!/bin/bash
echo -e "Available optical drives:"
lsblk -l | awk '/rom/ {print "/dev/"$1}' | nl -w1 -s". "
read -p "Enter drive number: " drive_number
drive=$(lsblk -l | awk '/rom/ {print "/dev/"$1}' | sed -n "${drive_number}p")
if [[ -z "$drive" ]]; then
    echo -e "\033[31mInvalid drive number.\033[0m"
    exit 1
fi
echo -e "Using drive: \033[33m$drive\033[0m"
isoutput=$(isoinfo -d -i "$drive" | grep -i -E 'block size|volume size')
if [[ $? -ne 0 ]]; then
    echo -e "\033[31mFailed to get ISO image information from $drive:\n$isoutput\033[0m"
    exit 1
fi
block=$(echo "$isoutput" | awk '/block size/ {gsub(/[^0-9]/,""); print}')
volume=$(echo "$isoutput" | awk '/Volume size/ {gsub(/[^0-9]/,""); print}')
echo -e "Block size identified ⇥ \033[33m$block\033[0m"
echo -e "Volume size identified ⇥ \033[33m$volume\033[0m"
read -p "Enter filename (with extension): " filename
if [[ -z "$filename" ]]; then
  echo -e "\033[31mFilename cannot be empty.\033[0m"
  exit 1
fi
if echo "$filename" | grep -Eq '[<>:"/\\|?*]'; then
  echo -e "\033[31mFilename contains invalid characters.\033[0m"
  exit 1
fi
trap 'echo -e "\033[31mExtraction interrupted.\033[0m"; exit 1' INT
dd if="$drive" of="$filename" bs="$block" count="$volume" status=progress 2>&1 > >(tee /dev/stderr)
ddcheck=$?
trap - INT
if [[ "$ddcheck" -ne 0 && "$ddcheck" -ne 130 ]]; then 
    echo -e "\033[31mExtraction failed.\033[0m"
    exit 1
fi
echo -e "\033[32mExtraction complete.\033[0m"
eject $(lsblk -no path "$drive")
