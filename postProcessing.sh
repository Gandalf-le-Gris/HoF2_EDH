#!/bin/bash

if [ $# -lt 1 ]; then
  echo "Usage : ./postProcessing [source folder]"
  exit 1
fi

WIDTH=1220
HEIGHT=2090

SOURCE=$1
OUTPUT=$1/processed

if [ ! -d $SOURCE ]; then
  echo "Folder not found"
  exit 1;
fi
TOTAL="$(find $SOURCE -maxdepth 1 -type f -exec file --mime-type {} \+ | awk -F: '{if ($2 ~/image\//) print $1}' | wc -l)"
if [ $TOTAL -gt 0 ]; then
  echo "$TOTAL image(s) found"
else
  echo "No image found"
  exit 0
fi

if ! hash convert 2>/dev/null; then
  echo "ImageMagick will be installed"
  sudo apt install imagemagick
fi
if ! hash convert 2>/dev/null; then
  echo "ImageMagick is required to run this script. Please try installing it manually if this doesn't work."
  exit 1
fi

if [ ! -d $OUTPUT ]; then
  mkdir -p $OUTPUT;
fi

function ProgressBar {
  let _progress=(${1}*100/${2}*100)/100
  let _done=(${_progress}*4)/10
  let _left=40-$_done
  _fill=$(printf "%${_done}s")
  _empty=$(printf "%${_left}s")
  printf "\r[${_fill// /#}${_empty// /-}] ${_progress}%%"
}

function ProgressOnce {
  ((_current++))
  ProgressBar ${_current} $(($TOTAL*3+1))
}

_current=0
MASK="$OUTPUT/.generatedcardmask.png"
_tmp="$OUTPUT/.tmp.png"

echo "Starting image post-processing"
ProgressBar 0 1
convert -size "${WIDTH}x${HEIGHT}" xc:black -fill white -draw "rectangle 0,0,${WIDTH},${HEIGHT}" $MASK
ProgressOnce

while read -r image; do
    W=$(identify -format %w "$image")
    if [ "$W" -ne "$WIDTH" ]; then
        convert "$image" -resize "$WIDTH" "$OUTPUT/$(basename "$image")"
    else
        cp "$image" "$OUTPUT/$(basename "$image")"
    fi
    ProgressOnce
    convert "$OUTPUT/$(basename "$image")" -matte $MASK -compose DstIn -composite $_tmp
    ProgressOnce
    convert $_tmp -background black -bordercolor "#B1A179" -border 54 -flatten "$OUTPUT/$(basename "$image")"
    ProgressOnce
done <<< "$(find $SOURCE -maxdepth 1 -type f -exec file --mime-type {} \+ | awk -F: '{if ($2 ~/image\//) print $1}')"

if [ -f $MASK ]; then
  rm $MASK
fi
if [ -f $_tmp ]; then
  rm $_tmp
fi

echo ""
echo "Done!"
