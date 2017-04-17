#!/bin/bash
set -e

## -------------------------------------------------------------------------- ##
## -------------------------------- Variables ------------------------------- ##
## -------------------------------------------------------------------------- ##

# Default encoder. (Set with installer script)
Encoder=__ENCODER__

# Set the default frame rate at which to capture (Range: whatever your system
# can handle, default = 16 because most systems suck). Be careful with this one.
# Setting it too high will use a lot of I/O and CPU.
Anim_FPS="16"

## ----------------------------- Flag Variables ----------------------------- ##

# Flag variable used to start video capture.
Animation=0

# Flag variable used to stop video capture.
kflag=0

# Flag variable used to trigger lossless capture.
Lossless=0

# Flag variable used to trigger help output.
hflag=0

# Flag variable used to disable preview after upload.
pflag=0

# Flag variable used to trigger uid input.
set_uid=0

# Flag variable used to contain the uid value.
uid=0

## ------------------------------ BPG Variables ----------------------------- ##

# Set quantizer parameter (Smaller gives better quality, Range: 0-51,
# default = 25)
BPG_Quality="25"

# Set the bit depth (8 to 12, default = 8)
BPG_Bitdepth="8"

# Set the preferred color space (ycbcr, rgb, ycgco, ycbcr_bt709, ycbcr_bt2020,
# default = ycbcr)
BPG_Colorspace="ycbcr"

# Set the preferred chroma format (420, 422, 444, default=444)
BPG_Chroma="444"

# Select the compression level (1=fast, 9=slow, default = 9). Please don't
# change this. 9 may be slower but it makes smaller file sizes.
BPG_Effort="9"

# Set the quantizer parameter for animation (options are: high, med, low)
BPG_Anim_Q="med"

## ---------------------------------- Flags --------------------------------- ##
# Setting variables with flags
while getopts "e:r:alhkpq:b:s:c:f:n:u:" flag; do
    case "${flag}" in
        e) Encoder="${OPTARG}" ;;
        r) Anim_FPS="${OPTARG}" ;;
        a) Animation=1 ;;
        l) Lossless=1 ;;
        h) hflag=1 ;;
        k) kflag=1 ;;
        p) pflag=1 ;;
        q) BPG_Quality="${OPTARG}" ;;
        b) BPG_Bitdepth="${OPTARG}" ;;
        s) BPG_Colorspace="${OPTARG}" ;;
        c) BPG_Chroma="${OPTARG}" ;;
        f) BPG_Effort="${OPTARG}" ;;
        n) BPG_Anim_Q="${OPTARG}" ;;
        u) uid="${OPTARG}" set_uid=1 ;;
    esac
done


## -------------------------- Pre-Function Setup  --------------------------- ##
# Change quality settings if taking animation
if [[ $Animation -eq 1 ]]; then
    if [[ $BPG_Anim_Q == "med" ]]; then
        BPG_Quality="29"
        BPG_Chroma="422"
    elif [[ $BPG_Anim_Q == "high" ]]; then
        BPG_Quality="20"
        BPG_Chroma="444"
    else
        BPG_Quality="39"
        BPG_Chroma="420"
    fi
fi

# Get UID from file and make the name
if [[ ! -f ~/.config/__PROGNAME__/sc.uid ]]; then
    echo "WARNING: UID is not set. Use -u to set UID."
    name="/tmp/0."$(date +%s)
else name="/tmp/"$(cat ~/.config/__PROGNAME__/sc.uid)"."$(date +%s); fi

# Add the extension to the name
if [[ $Encoder == "bpg" ]]; then name=$name".bpg"
elif [[ $Encoder == "flif" ]]; then name=$name".flif"; fi

## -------------------------------------------------------------------------- ##
## -------------------------------- Functions ------------------------------- ##
## -------------------------------------------------------------------------- ##

# Output help info
function helpme {
    echo -e "\n    Rarity Network Screenshot Util v1.0.0\n
Usage:             __PROGNAME__ [OPTIONS]\n
Description:       This is a command-line tool that takes a screenshot using
                   either FLIF or BPG and uploads it to Utils.Rarity.Network
Options:
  -h               Show this help message and exit
  -e bpg|flif      Sets the encoder to be used (Default: $Encoder)
  -u \`uid\`         Sets the uid and exits
  -p               Disable previewing
  -q 0-51          Quantizer parameter for bpg encoding (Default: $BPG_Quality)
  -b 8|10|12       Set the bit depth (Default: $BPG_Bitdepth)\n
  -s \`...\`         Set the color space for the bpg encoder (Default: \
$BPG_Colorspace)
                   (Options: ycbcr|rgb|ycgco|ycbcr_bt709|ycbcr_bt2020)\n
  -c 420|422|444   Set the chroma format for the bpg encoder (Default: \
$BPG_Chroma)
  -f 1-9           The effort to use when encoding with bpg (Default: \
$BPG_Effort)
  -l               Do a lossless encode
  -a               Start a video capture
  -k               Stop a video capture and start upload
  -r \`fps\`         Set the fps to capture video at (Default: $Anim_FPS)
  -n high|med|low  Quantizer parameter for bpg animation (Default: $BPG_Anim_Q)\n
Examples:
  __PROGNAME__
  __PROGNAME__ -pl -e bpg
  __PROGNAME__ -e flif
  __PROGNAME__ -a -r 20
  Same fps as when -a has to be specifide when -k is used
  __PROGNAME__ -k -r 20 -n high -e bpg
"
}

# Write the UID to file
function setuid {
    mkdir -p ~/.config/__PROGNAME__/
    echo $uid > ~/.config/__PROGNAME__/sc.uid
    echo "Successfully set UID to '"$uid"'"
}

# Upload the final image to Rarity Network and preview it
function upload {
    # Upload it and save output from curl
    local url=$(curl -i -X POST -H "Content-Type: multipart/form-data" \
           -F "file=@$name" https://utils.rarity.network/upload.php | grep url=)

    # Get image URL from output and add it to clipboard
    url=$(echo -n ${url:4}); echo -n $url | xsel -ib

    # Preview Check
    if [[ $pflag -eq 0 ]]; then $(__DEFAULTVIEWER__ /tmp/screenshot.png); fi

    # When previewing completes delete files
    rm /tmp/screenshot.png $name
}

# Capture the screenshot as a PNG
function tkss {
    maim -s -b 2 -c 1,0.2,1,0.8 /tmp/screenshot.png
    if [[ ! -f /tmp/screenshot.png ]]; then exit 1; fi
}

# Compress the PNG screenshot with BPG
function BPGenc {
    if [[ $1 -eq 1 ]]; then
        bpgenc -lossless -m 9 -c ycbcr_bt2020 -e jctvc -b $BPG_Bitdepth \
        /tmp/screenshot.png -o $name
    else
        bpgenc -q $BPG_Quality -b $BPG_Bitdepth -f $BPG_Chroma \
        -c $BPG_Colorspace -m $BPG_Effort /tmp/screenshot.png -o $name
    fi
}

# Compress the PNG screenshot with FLIF (Lossless only... For now)
function FLIFenc {
    flif -e -E 100 /tmp/screenshot.png $name
}

# Encode a BPG animation
function animBPGenc {
    bpgenc -a /tmp/screen_cap/%04d.PNG -fps $Anim_FPS -loop 0 -q $BPG_Quality \
           -b 8 -f $BPG_Chroma -m $BPG_Effort -o $name
    rm -r /tmp/screen_cap
}

# Capture the animation with ffmpeg
function capanim {
    mkdir /tmp/screen_cap
    eval $(slop -c 1,0.2,1,0.8 -b 2 -n)
    ffmpeg -r $Anim_FPS -f x11grab -s "$W"x"$H" -i "$DISPLAY".0+$X,$Y \
           /tmp/screen_cap/%04d.PNG & echo $! >>/tmp/screen_cap/prog.pid
}

# Stop ffmpeg from capturing
function killanim {
    kill -s TERM $(cat /tmp/screen_cap/prog.pid)
}

## -------------------------------------------------------------------------- ##
## ------------------------------- The Checks ------------------------------- ##
## -------------------------------------------------------------------------- ##

if [[ $hflag -eq 1 ]]; then
    helpme
elif [[ $set_uid -eq 1 ]]; then
    setuid
elif [[ $kflag -eq 1 ]]; then
    killanim
    animBPGenc
    upload
elif [[ $Lossless -eq 1 ]]; then
    if [[ $Encoder == "bpg" ]]; then
        tkss
        BPGenc 1
        upload
    elif [[ $Encoder == "flif" ]]; then
        tkss
        FLIFenc
        upload
    else
        echo "ERROR: Unkown encoder specified! (Use -h for help)"; exit 1
    fi
elif [[ $Animation -eq 1 ]]; then
    capanim
else
    if [[ $Encoder == "bpg" ]]; then
        tkss
        BPGenc
        upload
    elif [[ $Encoder == "flif" ]]; then
        tkss
        FLIFenc
        upload
    else
        echo "ERROR: Unkown encoder specified! (Use -h for help)"; exit 1
    fi
fi
