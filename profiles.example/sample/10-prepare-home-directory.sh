#!/bin/bash

read -n 1 -p "Shall we cut up and re-link the home folder? [Y,n] " ANS
echo

if [ "$ANS" != "N" -a "$ANS" != "n" ]; then
  # Make links

  read -n 1 -p "About to erase certain primary home file directories. ALL DATA IN THESE DIRECTORIES WILL BE LOST! Sure? [Y,n]: " USERSURE
  if [ "$USERSURE" = "n" ]; then
    echo 'Aborting.'
    exit
  fi

  rm -f "$HOMEDIR/.bashrc"
  rm -fR "$HOMEDIR/Books"
  rm -fR "$HOMEDIR/Code Library"
  rm -fR "$HOMEDIR/Configuration Files"
  rm -fR "$HOMEDIR/Current"
  rm -fR "$HOMEDIR/Documents"
  rm -fR "$HOMEDIR/.fonts"
  rm -fR "$HOMEDIR/Music"
  rm -fR "$HOMEDIR/Pictures"
  rm -f  "$HOMEDIR/.profile"
  rm -fR "$HOMEDIR/Project Files"
  rm -fR "$HOMEDIR/.ssh"
  rm -fR "$HOMEDIR/.thunderbird"
  rm -fR "$HOMEDIR/.unison"
  rm -fR "$HOMEDIR/Videos"

  #Extras
  rm -fR "$HOMEDIR/Examples"
  rm -fR "$HOMEDIR/Templates"

  ln -s "$SHAREMOUNT/Configuration Files/linux/home/kael/bashrc" "$HOMEDIR/.bashrc"
  ln -s "$SHAREMOUNT/Books" "$HOMEDIR/Books"
  ln -s "$SHAREMOUNT/Code Library" "$HOMEDIR/Code Library"
  ln -s "$SHAREMOUNT/Configuration Files" "$HOMEDIR/Configuration Files"
  ln -s "$SHAREMOUNT/../Current" "$HOMEDIR/Current"
  ln -s "$SHAREMOUNT/Documents" "$HOMEDIR/Documents"
  ln -s "$SHAREMOUNT/Configuration Files/linux/home/kael/fonts" "$HOMEDIR/.fonts"
  ln -s "$SHAREMOUNT/Music" "$HOMEDIR/Music"
  ln -s "$SHAREMOUNT/Pictures" "$HOMEDIR/Pictures"
  ln -s "$SHAREMOUNT/Configuration Files/linux/home/kael/profile" "$HOMEDIR/.profile"
  ln -s "$SHAREMOUNT/Project Files" "$HOMEDIR/Project Files"
  ln -s "$SHAREMOUNT/Configuration Files/linux/home/kael/ssh" "$HOMEDIR/.ssh"
  ln -s "$SHAREMOUNT/Configuration Files/linux/home/kael/thunderbird" "$HOMEDIR/.thunderbird"
  ln -s "$SHAREMOUNT/Configuration Files/linux/home/kael/unison" "$HOMEDIR/.unison"
  ln -s "$SHAREMOUNT/Videos" "$HOMEDIR/Videos"

  # Allow for shared base configuration without having sync wars
  echo -n "Should we copy over your standard config? [Y,n]: "
  read USERCONF
  if [ "$USERCONF" = "n" ]; then
    echo
  else
    rm -fR "$HOMEDIR/.config/dconf"
    rm -fR "$HOMEDIR/.config/xfce4"
    echo -n "\nWould you rather link the configuration to maintain it synchronized, or copy it over as a starting point? (If this is your primary computer, it might be better to link it.) [C,l]: "
    read COPYORLINK
    if [ "$COPYORLINK" = "l" -o "$COPYORLINK" = "L" ]; then
      ln -s "$SHAREMOUNT/Configuration Files/linux/home/kael/config/dconf" "$HOMEDIR/.config/"
      ln -s "$SHAREMOUNT/Configuration Files/linux/home/kael/config/xfce4" "$HOMEDIR/.config/"
    else
      cp -R "$SHAREMOUNT/Configuration Files/linux/home/kael/config/dconf" "$HOMEDIR/.config/"
      cp -R "$SHAREMOUNT/Configuration Files/linux/home/kael/config/xfce4" "$HOMEDIR/.config/"
    fi
  fi

  if [ -e "$HOMEDIR/.mime.types" ]; then
    cat "$HOMEDIR/.mime.types" >> "$SHAREMOUNT/Configuration Files/linux/home/kael/mime.types"
    rm "$HOMEDIR/.mime.types"
  fi

  ln -s "$SHAREMOUNT/Configuration Files/linux/home/kael/mime.types" "$HOMEDIR/.mime.types"

  sudo chown -R $USERNAME:$USERNAME "$HOMEDIR"

  echo
  echo -n "Home directory prepared! "
fi


