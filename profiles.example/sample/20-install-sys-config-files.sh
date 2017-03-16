#!/bin/bash

# Incorporate any system config file I might want.
# (You can store these anywhere, but my convention is to put them in [migrate-me]/profiles/shared-files
# so that you can access them from multiple profiles)

read -n 1 -p "Incorporate system config files? [Y,n] " ANS
echo
if [ "$ANS" != "N" -a "$ANS" != "n" ]; then
  # Link system config files
  sudo ln -sfn "$SHARED_FILES/linux/etc/vimrc" /etc/vim/vimrc.local
  if [ "$?" -gt 0 ]; then echo "Couldn't link vimrc file :("; exit 1; fi

  sudo ln -sfn "$SHARED_FILES/linux/usr/local/src" /usr/local/src/packages
  if [ "$?" -gt 0 ]; then echo "Couldn't link packages directory :("; exit 1; fi

  # etc....

fi

