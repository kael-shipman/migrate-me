#!/bin/bash

# If you need to set up special permissions, do so.
# Otherwise, skip

read -n 1 -p "Grant special user permissions? [Y,n] " ANS
echo
if [ "$ANS" != "N" -a "$ANS" != "n" ]; then

  # Create special dirs, in case they don't already exist
  sudo mkdir -p /media/$USERNAME
  sudo mkdir -p /usr/local/programs

  sudo setfacl -R -m user:$USERNAME:rwX,default:user:$USERNAME:rwX /etc
  sudo setfacl -R -m user:$USERNAME:rwX,default:user:$USERNAME:rwX /media/$USERNAME
  sudo setfacl -R -m user:$USERNAME:rwX,default:user:$USERNAME:rwX /usr/local/programs
  sudo setfacl -R -m user:$USERNAME:rwX,default:user:$USERNAME:rwX /usr/local/src
fi


