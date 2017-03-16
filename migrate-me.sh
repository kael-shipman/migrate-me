#!/bin/bash


function exit_on_fail {
  if [[ ! "$1" =~ ^[0-9]+$ ]]; then
    echo "Error: Received text instead of number for first argument. (Fail message: $1)" >&2
    echo >&2
    echo "Intended usage:" >&2
    echo >&2
    echo '  exit_on_fail $(your-command-here --your-argument=1 -o && echo $?) '"'"'Put your failure message here'"'" >&2
    echo >&2
    echo 'Note that the "&& echo $?" part is crucial, as this returns the exit code of your command to the exit_on_fail function' >&2
    echo >&2
    exit 2
  elif [ "$1" -gt 0 ]; then
    echo "$2" >&2
    exit 1
  fi
}

export -f exit_on_fail

export SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
export SCRIPT_VER=1





echo
echo "**************************************************"
echo "-- Welcome to the New System Migration console! --"
echo "**************************************************"
echo

PROFILE=$1
if [ "$PROFILE" == "" ]; then
  if [ ! -e "$SCRIPT_DIR/profiles/default" ]; then
    echo "No default profile defined! Please create a symlink called 'default' to your desired default profile subfolder in the 'profiles' folder"
    exit 1
  else
    PROFILE=$(basename "`readlink -f "$SCRIPT_DIR/profiles/default"`")
    echo "Using default profile '$PROFILE'."
  fi
else
  if [ ! -e "$SCRIPT_DIR/profiles/$PROFILE" ]; then
    echo "Profile '$PROFILE' not found! please make sure it exists and try again."
    exit 1
  else
    echo "Using profile '$PROFILE'."
  fi
fi

export PROFILE

export CONFIG_DIR=~/.config/migrate-me/"$PROFILE"
mkdir -p "$CONFIG_DIR"



echo

# Run all scripts for given profile
for script in "$SCRIPT_DIR/profiles/$PROFILE/"*.sh ; do
  BASENM=`basename "$script"`
  if [ "$BASENM" == "00-prelims.sh" -o ! -e "$CONFIG_DIR/$BASENM" ]; then
    echo "Running $BASENM...."
    . "$script"
    echo "Done."
    echo
    touch "$CONFIG_DIR/$BASENM"
  else
    echo "Already ran $BASENM. Proceeding to next script."
  fi
done


echo
echo 'All scripts have been run. System should be ready to go!'
echo
exit

