#!/bin/bash

## Variables

# Set which encoder to use (options are: bpg or flif, default = bpg). FLIF is
# not ready yet. FLIF support will be coming soon! (and maybe WebP if I'm
# feeling bold)
Encoder='bpg'

# Set the frame rate at which to capture (Range: whatever your system can
# handle, default = 16 because most systems suck). Be careful with this one.
# Setting it too high will use a lot of I/O and CPU.
Anim_FPS="16"

# TODO: Document this
Animation=0

# TODO: Document this
Lossless=0

# TODO: Document this
hflag=0

# TODO: Document this
kflag=0

# TODO: Document this
set_uid=0

# TODO: Document this
uid=0

## BPG Variables

# Set quantizer parameter (Smaller gives better quality, Range: 0-51,
# default = 25)
BPG_Quality='25'

# Set the bit depth (8 to 12, default = 8)
BPG_Bitdepth='8'

# Set the preferred color space (ycbcr, rgb, ycgco, ycbcr_bt709, ycbcr_bt2020,
# default = ycbcr)
BPG_Colorspace='ycbcr'

# Set the preferred chroma format (420, 422, 444, default=444)
BPG_Chroma='444'

# Select the compression level (1=fast, 9=slow, default = 9). Please don't
# change this. 9 may be slower but it makes smaller file sizes.
BPG_Effort='9'

# Set the quantizer parameter for animation (options are: high, medium, low)
BPG_Anim_Q='medium'

##  FLIF Variables

# Setting vars with flags

while getopts 'e:r:alhkq:b:s:c:f:n:u:' flag; do
  case "${flag}" in
    e) _Encoder="${OPTARG}" ;;
    r) Anim_FPS="${OPTARG}" ;;
    a) Animation=1 ;;
    l) Lossless=1 ;;
    h) hflag=1 ;;
    k) kflag=1 ;;
    q) BPG_Quality="${OPTARG}" ;;
    b) BPG_Bitdepth="${OPTARG}" ;;
    s) BPG_Colorspace="${OPTARG}" ;;
    c) BPG_Chroma="${OPTARG}" ;;
    f) BPG_Effort="${OPTARG}" ;;
    n) BPG_Anim_Q="${OPTARG}" ;;
    u) uid="${OPTARG}" set_uid=1 ;;
  esac
done

if [[ $Animation -eq 1 ]]
then
  if [[ $BPG_Anim_Q == 'medium' ]]
  then
    BPG_Quality='29'
    BPG_Chroma='420'
  elif [[ $BPG_Anim_Q == 'high' ]]
  then
    BPG_Quality='20'
    BPG_Chroma='444'
  else
    BPG_Quality='39'
    BPG_Chroma='420'
  fi
fi


if [[ $set_uid -eq 1 ]]
then
  mkdir ~/.config/screenshot/
  echo $uid > ~/.config/screenshot/sc.uid
fi

name=$(cat ~/.config/screenshot/sc.uid)'.'$(date +%s)

## Functions

function helpme {
  echo "help not ready yet!"
}

function upload {
  url=$(curl -i -X POST -H "Content-Type: multipart/form-data" -F "uid=$uid" \
             -F "file=@/tmp/$1" https://utils.rarity.network/upload.php \
            | grep url=)
  url=$(echo -n ${url:4})
  echo -n $url | xsel -ib
  if [[ $_Encoder == "bpg" ]]
  then
    bpgview /tmp/$1
  elif [[ $_Encoder == "flif" ]]
  then
    viewflif /tmp/$1
  fi
  rm /tmp/$1
}

function tkss {
  maim -s -b 2 -c 1,0.2,1,0.8 /tmp/screenshot.png
}

function BPGenc {
  if [[ $1 -eq 1 ]]
  then
    bpgenc -lossless -m 9 -c ycbcr_bt2020 -e jctvc /tmp/screenshot.png \
         -o /tmp/$name.bpg
  else
    bpgenc -q $BPG_Quality -b $BPG_Bitdepth -f $BPG_Chroma -c $BPG_Colorspace \
           -m $BPG_Effort /tmp/screenshot.png -o /tmp/$name.bpg
  fi
  rm /tmp/screenshot.png
}

function FLIFenc {
  flif -e -E 100 /tmp/screenshot.png /tmp/$name.flif
  rm /tmp/screenshot.png
}

function animBPGenc {
  bpgenc -a /tmp/screen_cap/%04d.PNG -fps $Anim_FPS -loop 0 -q $BPG_Quality \
         -b 8 -f $BPG_Chroma -m $BPG_Effort -o /tmp/$name.bpg
  rm -r /tmp/screen_cap
}

function capanim {
  mkdir /tmp/screen_cap
  eval $(slop -c 1,0.2,1,0.8 -b 2 -n)
  ffmpeg -r $Anim_FPS -f x11grab -s "$W"x"$H" -i "$DISPLAY".0+$X,$Y \
         /tmp/screen_cap/%04d.PNG & echo $! >>/tmp/screen_cap/prog.pid
}

function killanim {
  kill -s TERM $(cat /tmp/screen_cap/prog.pid)
}

## The Checks

if [[ $hflag -eq 1 ]]
then
  helpme
elif [[ $kflag -eq 1 ]]
then
  killanim
  animBPGenc
  upload $name.bpg
elif [[ $Lossless -eq 1 ]]
then
  if [[ $_Encoder == 'bpg' ]]
  then
    tkss
    BPGenc 1
    upload $name.bpg
  elif [[ $_Encoder == 'flif' ]]
  then
    tkss
    FLIFenc
    upload $name.flif
  else
    echo 'Unkown encoder specified!'
  fi
elif [[ $Animation -eq 1 ]]
then
  capanim
else
  if [[ $_Encoder == 'bpg' ]]
  then
    tkss
    BPGenc
    upload $name.bpg
  elif [[ $_Encoder == 'flif' ]]
  then
    tkss
    FLIFenc
    upload $name.flif
  else
    echo 'Unkown encoder specified!'
  fi
fi
