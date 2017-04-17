#!/bin/bash
set -e

echo -e "\n *** Screenshot Installer ***\n"

read -p "Name: [Leave empty for 'screenshot'] " name
if [[ $name == "" ]]; then name="screenshot"; fi
echo -e "Installing As:\n\n"$name"\n"

read -p "Image Viewer for Preview: [Leave empty for 'eog'] " defviewer
if [[ $defviewer == "" ]]; then defviewer=eog; fi
echo -e "Using:\n\n"$defviewer"\n"

read -p "Default Encoder ('flif' or 'bpg'): [Leave empty for 'bpg'] " encoder
if [[ $encoder == "" ]]; then encoder="bpg"; fi
echo -e "Using:\n\n"$encoder"\n"

read -p ":: Proceed with installation? [Y/n] " yn
if [[ $yn == "y" ]] || [[ $yn == "Y" ]]; then

    sed '2,${/#/d;/^$/d}' ./screenshot.sh > ./$name

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
