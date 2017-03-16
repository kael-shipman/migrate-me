#!/bin/bash

sudo apt-get update

# Uninstall unneeded software
sudo apt-get --purge remove darktable '^php[5-7](\.[0-9]+)*.*$' '^mysql.*'
if [ "$?" -gt 0 ]; then echo "Error uninstalling software"; exit 1; fi

#Primary programs
sudo apt-get --no-install-recommends -y install sudo vim thunderbird artha gparted acl vlc git chromium-browser gnucash xfce4-xkb-plugin screen libreoffice screen sqlite3
if [ "$?" -gt 0 ]; then echo "Error installing primary programs"; exit 1; fi

# General Dependencies for Programs I compile
sudo apt-get --no-install-recommends -y install zlib1g zlib1g-dev libbz2-1.0 libbz2-dev libxml2 libxml2-dev libssl1.0.0 libssl-dev libpng12-0 libpng12-dev libjpeg8 libjpeg8-dev libpcre3 libpcre3-dev gnupg2 libsqlite3-0 libsqlite3-dev gcc g++ bzip2 
if [ "$?" -gt 0 ]; then echo "Error installing depedencies for common programs I compile"; exit 1; fi

