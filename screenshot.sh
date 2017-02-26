#!/bin/bash

## -------------------------------------------------------------------------- ##
## -------------------------------- Variables ------------------------------- ##
## -------------------------------------------------------------------------- ##

# Set your default image viewing program here. eg.(feh, eog, mirage, gpicvew)
defviewer=eog

# Set the default encoder to use (options are: bpg or flif, default = bpg).
Encoder="bpg"

# Set the default frame rate at which to capture (Range: whatever your system
# can handle, default = 16 because most systems suck). Be careful with this one.
# Setting it too high will use a lot of I/O and CPU.
Anim_FPS="16"

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

# Set the quantizer parameter for animation (options are: high, medium, low)
BPG_Anim_Q="medium"

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

# Change quality settings if taking animation
if [[ $Animation -eq 1 ]]; then
    if [[ $BPG_Anim_Q == "medium" ]]; then
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

# Write the UID to file
if [[ $set_uid -eq 1 ]]; then
    mkdir -p ~/.config/screenshot/
    echo $uid > ~/.config/screenshot/sc.uid
fi

# Get UID from file and make the name
if [[ ! -f ~/.config/screenshot/sc.uid ]]; then
    echo "WARNING: UID is not set. Use -u to set UID."
    name="/tmp/0."$(date +%s)
else name="/tmp/"$(cat ~/.config/screenshot/sc.uid)"."$(date +%s); fi

# Add the extension to the name
if [[ $Encoder == "bpg" ]]; then name=$name".bpg"
elif [[ $Encoder == "flif" ]]; then name=$name".flif"; fi

## -------------------------------------------------------------------------- ##
## -------------------------------- Functions ------------------------------- ##
## -------------------------------------------------------------------------- ##

# Output help info
function helpme {
    echo "help not ready yet! ;p"
}

# Upload the final image to Rarity Network and preview it
function upload {
    # Upload it and save output from curl
    url=$(curl -i -X POST -H "Content-Type: multipart/form-data" \
           -F "file=@$name" https://utils.rarity.network/upload.php | grep url=)

    # Get image URL from output and add it to clipboard
    url=$(echo -n ${url:4}); echo -n $url | xsel -ib

    # Preview Check
    if [[ $pflag -eq 0 ]]; then $($defviewer /tmp/screenshot.png); fi

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
        echo "ERROR: Unkown encoder specified!"; exit 1
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
        echo "ERROR: Unkown encoder specified!"; exit 1
    fi
fi
