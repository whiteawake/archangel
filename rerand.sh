#!/bin/bash
for filename in *
do
  ext="${filename##*.}"
  mv "$filename" "$(shuf -i 1000000000-9999999999 -n 1).$ext"
done
