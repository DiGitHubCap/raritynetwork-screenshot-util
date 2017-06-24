#!/bin/bash
set -e

## -------------------------------------------------------------------------- ##
## -------------------------------- Variables ------------------------------- ##
## -------------------------------------------------------------------------- ##

# Default encoder. (Set with installer script)
Encoder=__ENCODER__

# Extension variable
ext=""

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

# Flag variable used to toggle direct link.
dflag=0

# Flag variable used to toggle heavy compression for PNGs.
cflag=0

# Flag variable used to trigger uid input.
set_uid=0

# Flag variable used to contain the uid value.
uid=0

# Quality to use for JPEG encoding
quality=95

## ---------------------------------- Flags --------------------------------- ##
# Setting variables with flags
while getopts "alhkpdcu:q:r:e:" flag; do
    case "${flag}" in
        a) Animation=1 ;;
        l) Lossless=1 ;;
        h) hflag=1 ;;
        k) kflag=1 ;;
        p) pflag=1 ;;
        d) dflag=1 ;;
        c) cflag=1 ;;
        u) uid="${OPTARG}" set_uid=1 ;;
        q) quality="${OPTARG}" ;;
        r) Anim_FPS="${OPTARG}" ;;
        e) Encoder="${OPTARG}" ;;
    esac
done

## -------------------------- Pre-Function Setup  --------------------------- ##
# Get UID from file and make the name
if [[ ! -f ~/.config/__PROGNAME__/sc.uid ]]; then
    echo "WARNING: UID is not set. Use -u to set UID."
    name="/tmp/0."$(date +%s)
else name="/tmp/"$(cat ~/.config/__PROGNAME__/sc.uid)"."$(date +%s); fi

# Add the extension to the name
if [[ $kflag -eq 1 ]]; then ext=".apng"
elif [[ $Encoder == "png" ]]; then ext=".png"
elif [[ $Encoder == "jpeg" ]]; then ext=".jpg"; fi
name=$name$ext

## -------------------------------------------------------------------------- ##
## -------------------------------- Functions ------------------------------- ##
## -------------------------------------------------------------------------- ##

# Output help info
function helpme {
    echo -e "\n    Rarity Network Screenshot Util v2.1.0\n
Usage:             __PROGNAME__ [OPTIONS]\n
Description:       This is a command-line tool that takes a screenshot using
                   either PNG/APNG or JPG and uploads it to Utils.Rarity.Network
Options:
  -h               Show this help message and exit
  -e png|jpeg      Sets the encoder to be used (Default: $Encoder)
  -u 'uid'         Sets the uid and exits
  -p               Disable previewing. Off by default
  -d               Return direct link. Off by default
  -c               Turns on heavy compression for PNG. Off by default
  -q 1-100         Quality parameter for JPEG encoding (Default: $quality)
  -l               Do a lossless encode
  -a               Start a video capture
  -k               Stop a video capture and start upload
  -r 'fps'         Set the fps to capture video at (Default: $Anim_FPS)
Examples:
  __PROGNAME__ -e png -cd
  __PROGNAME__ -pl -e jpeg
  __PROGNAME__ -e png
  __PROGNAME__ -a -r 20
  Same fps as when -a has to be specifide when -k is used
  __PROGNAME__ -k -r 20
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
    echo "Starting upload!"
    local url=$(curl -i -X POST -H "Content-Type: multipart/form-data" \
           -F "file=@$name" https://utils.rarity.network/upload.php | grep url=)
    # Get image URL from output and add it to clipboard
    url=$(echo -n ${url:4})
    # Check if user wants direct link and set it
    if [[ $dflag -eq 1 ]]; then
        url=$(echo $url | sed "s/\/img\//\/images\//g")$ext; fi
    echo -n $url | xsel -ib

    # Preview Check
    if [[ $pflag -eq 0 ]]; then $(__DEFAULTVIEWER__ $name); fi

    # When previewing completes delete files
    rm $name
}

# Capture the screenshot as a PNG
function tkss {
    maim -s -b 2 -c 1,0.2,1,0.8 /tmp/screenshot.png
    if [[ ! -f /tmp/screenshot.png ]]; then exit 1; fi
}

# Compress the PNG screenshot with zopflipng
function PNGenc {
    if [[ $cflag -eq 1 ]]; then filter=0e; else filter=12; fi
    zopflipng -q -y --filters=$filter --iterations=0 --lossy_8bit \
              --lossy_transparent  /tmp/screenshot.png $name
    rm /tmp/screenshot.png
}

# Compress the PNG screenshot with mozjpeg
function JPGenc {
    if [[ $Lossless -eq 1 ]]; then quality=100; fi
    /opt/mozjpeg/bin/cjpeg -quality $quality -dct float -quant-table 4 \
                           -outfile $name /tmp/screenshot.png
    rm /tmp/screenshot.png
}

# Capture the animation with ffmpeg
function capanim {
    eval $(slop -c 1,0.2,1,0.8 -b 2 -n)
    ffmpeg -r $Anim_FPS -f x11grab -s "$W"x"$H" -i "$DISPLAY".0+$X,$Y \
           -pix_fmt rgb24 -plays 0 /tmp/screenshot.apng & \
        echo $! >> /tmp/ssffmpeg.pid
}

# Stop ffmpeg from capturing
function killanim {
    kill -s TERM $(cat /tmp/ssffmpeg.pid)
    rm /tmp/ssffmpeg.pid
    mv /tmp/screenshot.apng $name
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
    upload
elif [[ $Animation -eq 1 ]]; then
    capanim
else
    if [[ $Encoder == "png" ]]; then
        tkss
        PNGenc
        upload
    elif [[ $Encoder == "jpeg" ]]; then
        tkss
        JPGenc
        upload
    else
        tkss
        JPGenc
        upload
    fi
fi
