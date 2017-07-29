#!/bin/bash
set -e
echo -e "\n *** Screenshot Installer ***\n\nChecking Dependencies..."
command -v curl >/dev/null 2>&1 && echo "Found: curl" || { echo >&2 "ERROR: Missing Dependency 'curl'. Aborting!"; exit 1; }
command -v xsel >/dev/null 2>&1 && echo "Found: xsel" || { echo >&2 "ERROR: Missing Dependency 'xsel'. Aborting!"; exit 1; }
command -v maim >/dev/null 2>&1 && echo "Found: maim" || { echo >&2 "ERROR: Missing Dependency 'maim'. Aborting!"; exit 1; }
command -v slop >/dev/null 2>&1 && echo "Found: slop" || { echo >&2 "ERROR: Missing Dependency 'slop'. Aborting!"; exit 1; }
command -v zopflipng >/dev/null 2>&1 && echo "Found: zopflipng" || { echo >&2 "ERROR: Missing Dependency 'zopflipng'. Aborting!"; exit 1; }
command -v /opt/mozjpeg/bin/cjpeg >/dev/null 2>&1 && echo "Found: mozjpeg" || { echo >&2 "ERROR: Missing Dependency 'cjpeg'. Make sure it's in '/opt/mozjpeg/bin/'. Aborting!"; exit 1; }
command -v ffmpeg >/dev/null 2>&1 && echo "Found: ffmpeg" || { echo >&2 "WARNING: Missing Optional Dependency 'ffmpeg'."; }

echo ""
read -p "Name: [Leave empty for 'screenshot'] " name
if [[ $name == "" ]]; then name="screenshot"; fi
echo -e "Installing As:\n\n"$name"\n"

read -p "Image Viewer for Preview: [Leave empty for 'eog'] " defviewer
if [[ $defviewer == "" ]]; then defviewer=eog; fi
echo -e "Using:\n\n"$defviewer"\n"

read -p "Default Encoder (png or jpeg): [Leave empty for 'jpeg'] " encoder
if [[ $encoder == "" ]]; then encoder="jpeg"; fi
echo -e "Using:\n\n"$encoder"\n"

read -p ":: Proceed with installation? [Y/n] " yn
if [[ $yn == "y" ]] || [[ $yn == "Y" ]]; then

    sed -i "s/__PROGNAME__/"$name"/g" ./$name
    sed -i "s/__DEFAULTVIEWER__/"$defviewer"/g" ./$name
    sed -i "s/__ENCODER__/"$encoder"/g" ./$name

    chmod +x ./$name
    sudo mv ./$name /usr/bin/$name

    # Fake Progress Bar
    tleng=$(($(tput cols) - 25))
    echo -en "\nInstalling...   ["
    i=1
    while [ $i -le $tleng ]; do
        echo -n "-"
        ((i++))
    done
    echo -ne "]\b"
    i=1
    while [ $i -le $tleng ]; do
        echo -ne "\b"
        ((i++))
    done
    i=1
    while [ $i -le $tleng ]; do
        echo -n "#"
        sleep .0015
        ((i++))
    done
    echo -e "] Done!\n"
    sleep 0.25
fi
