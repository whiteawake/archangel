#!/bin/bash
read -p "Enter disc name: " cdda_name
echo "Navigating base directory…"
cd "$HOME/Music"
echo "Directory located."
echo "Creating destination directory…"
mkdir "/home/asha/Music/CDDA Extraction/$cdda_name"
cd "$cdda_name"
echo "Directory created and entered."
echo "Attempting extraction — $cdda_name from /dev/sr0…"
sleep 5
cdrdao read-cd --datafile $cdda_name.bin --driver generic-mmc:0x20000 --device /dev/sr0 --read-raw $cdda_name.toc
echo "Extraction completed."
sleep 5
echo "Generating cue sheet…"
toc2cue $cdda_name.toc $cdda_name.cue
echo "Cue sheet generated."
read -p "Extract waveform files? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Extracting .WAV files…"
  bchunk -w $cdda_name.bin $cdda_name.cue "${cdda_name}_"
  echo "CDDA extraction and waveform conversion complete."
else
  echo "CDDA extraction complete."
fi
