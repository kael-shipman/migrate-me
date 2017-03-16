#!/bin/bash


#
# Functions
#

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

function echo_usage {
  echo "$0 - migrate a system setup to a new system"
  echo
  echo "$0 [options] [profile]"
  echo
  echo "Options:"
  echo "  -h, --help                      show this help"
  echo "  -p [dir], --profile-dir [dir]   set the directory in which to find profiles"
  echo "  -c [dir], --config-dir [dir]    set the directory in which to find migrate-me config"
  echo
  echo
}





#
# Get arguments
#

while test $# -gt 0; do
  case $1 in
    -h|--help)
      echo_usage
      exit 0
      ;;
    
    -c|--config-dir)
      shift
      if test $# -gt 0; then
        CONFIG_DIR="$1"
        shift
      else
        echo "No config directory specified, even though -c or --config-dir parameter passed!"
        exit 1
      fi
      ;;

    -p|--profile-dir)
      shift
      if test $# -gt 0; then
        PROFILE_DIR="$1"
        shift
      else
        echo "No profile directory specified, even though -p or --profile-dir parameter passed!"
        exit 1
      fi
      ;;

    *)
      if [ "$PROFILE" != "" ]; then
        echo "You have unknown arguments!"
        echo_usage
        exit 1
      fi
      PROFILE=$1
      shift
      ;;

  esac
done




#
# Validate parameters
#

if [ "$CONFIG_DIR" == "" ]; then
  CONFIG_DIR=~/.config/migrate-me
fi
if [ "$PROFILE_DIR" == "" ]; then
  PROFILE_DIR="profiles"
  DEFAULT_PRF_DIR=1
else
  DEFAULT_PRF_DIR=0
fi
if [ ! -d "$CONFIG_DIR" ]; then
  read -n 1 -p "Config dir '$CONFIG_DIR' doesn't exist. Would you like to create it? [Y,n] " ANS
  if [ "$ANS" != 'N' -a "$ANS" != 'n' ]; then
    mkdir -p "$CONFIG_DIR"
  else
    echo
    echo "Need a valid config directory to proceed"
    exit 1
  fi
fi
if [ "$DEFAULT_PRF_DIR" -eq 1 ]; then
  PROFILE_DIR="$CONFIG_DIR/$PROFILE_DIR"
  if [ ! -d "$CONFIG_DIR/$PROFILE_DIR" ]; then
    mkdir -p "$PROFILE_DIR"
  fi
else
  if [ ! -d "$PROFILE_DIR" ]; then
    read -n 1 -p "Profile dir '$PROFILE_DIR' is neither an existing standalone folder nor a subfolder of the config dir ($CONFIG_DIR). Would you like to create it? [Y,n] " ANS
    if [ "$ANS" != 'N' -a "$ANS" != 'n' ]; then
      mkdir -p "$PROFILE_DIR"
    else
      echo
      echo "Need a valid profile directory"
      exit 1
    fi
  fi
fi

if [ "$PROFILE" == "" ]; then
  if [ ! -d "$PROFILE_DIR/default" ]; then
    echo "You haven't provided a profile and there is no default profile available in '$PROFILE_DIR'. If you'd like to create a default profile, create a symlink or folder called 'default' under the profile directory '$PROFILE_DIR'."
    exit 1
  else
    PROFILE=$(basename "`readlink -f "$PROFILE_DIR/default"`")
    echo "Using default profile '$PROFILE'."
  fi
else
  if [ ! -d "$PROFILE_DIR/$PROFILE" ]; then
    echo "Profile '$PROFILE' not found at '$PROFILE_DIR/$PROFILE'! please make sure it exists and try again."
    exit 1
  fi
fi

SHARED_FILES="$PROFILE_DIR/shared-files"
DONE_DIR="$CONFIG_DIR/done/$PROFILE"
mkdir -p "$DONE_DIR"



#
# Export variables so other scripts can use them
#

export -f exit_on_fail
export SCRIPT_VER=1
export CONFIG_DIR
export PROFILE_DIR
export PROFILE
export SHARED_FILES
export DONE_DIR




echo
echo "**************************************************"
echo "-- Welcome to the New System Migration console! --"
echo "**************************************************"
echo
echo ":: Using profile '$PROFILE'."
echo





echo

# Run all scripts for given profile
for script in "$PROFILE_DIR/$PROFILE/"*.sh ; do
  BASENM=`basename "$script"`
  if [ "$BASENM" == "00-prelims.sh" -o ! -e "$DONE_DIR/$BASENM" ]; then
    echo "Running $PROFILE/$BASENM...."
    . "$script"
    echo "Done."
    echo
    touch "$DONE_DIR/$BASENM"
  else
    echo "Already ran $PROFILE/$BASENM. Proceeding to next script."
  fi
done


echo
echo 'All scripts have been run. System should be ready to go!'
echo
exit
