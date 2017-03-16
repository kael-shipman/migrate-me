#!/bin/bash

# Note: 00-prelims.sh is a special file that will be run every time the migrate-me.sh script is run.
# This is in contrast to other files, which will only run once unless they exit with errors (in which case
# they'll be re-run the next time).


# This check is typically a good idea. When setting things up, you'll want to do it as your user, and your scripts should invoke
# sudo whenever necessary
USERNAME=`whoami`
if [ "$USERNAME" = "root" ]; then
  echo "It looks like you're setting up using sudo or the root account. Please run this script with your basic user account instead."
  exit 1
fi


# From here, you can do any other setup that you might want. Any variables you create will be available in all scripts that follow
# In the following example, we create a mount point for a shared files partition that we'll be using as our file base in future
# scripts:

# echo
# echo -n "Please type the shared volume mount point (e.g., /home/kael/.archive/archive): "
# read SHAREMOUNT
# while [ ! -e "$SHAREMOUNT" ]; do
#   echo -n "The directory you supplied ($SHAREMOUNT) doesn't exist! Please try again: "
#   read SHAREMOUNT
# done
# 
# HOMEDIR="/home/$USERNAME"

