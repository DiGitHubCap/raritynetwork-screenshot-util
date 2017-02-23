#!/bin/sh
sed '2,${/#/d;/^$/d}' ./screenshot.sh > ./screenshot
chmod +x ./screenshot
sudo mv ./screenshot /usr/bin/screenshot
