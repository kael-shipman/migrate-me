#!/bin/bash

export SCRIPT_VER=2.2

vers=`/bin/bash --version 2>/dev/null | sed -Ez 's/.*version ([4-9]).*/\1/'`
if [ "$vers" -lt 4 ]; then
    echo
    echo "ERROR: This utility requires bash version 4 or greater. Tried to get version by"
    echo "sedding output from /bin/bash --version."
    echo
    echo "Exiting :("
    echo
    exit 1
fi

#
# Functions
#

function lecho {
    logme "$1"
    echo "$1"
}

function logme {
    echo "$1" >> $LOGFILE
}

function exit_on_fail {
  if [[ ! "$1" =~ ^[0-9]+$ ]]; then
    echo "Error: Received text instead of number for first argument." >&2
    echo "  (Arg 1: $1)" >&2
    echo "  (Arg 2: $2)" >&2
    echo >&2
    echo "Intended usage:" >&2
    echo >&2
    echo '  ' >&2
    echo '  exit_on_fail $(your-command-here --your-argument=1 -oh; echo "$?") '"'"'Put your failure message here'"'" >&2
    echo >&2
    echo 'NOTE: The `echo "$?"` part is crucial, as this returns the exit code of your command to the function, telling it whether or not the command was a success' &>2
    exit 2
  elif [ "$1" -gt 0 ]; then
    logme "$2"
    echo "$2" >&2
    exit 1
  fi
}

function echo_usage {
  echo "$0 - migrate a system setup to a new system"
  echo
  echo "$0 [options] profile"
  echo
  echo "Options:"
  echo "  -h, --help                      show this help"
  echo "  -p [dir], --profile-dir [dir]   set the directory in which to find profiles"
  echo "  -c [dir], --config-dir [dir]    set the directory in which to find migrate-me config"
  echo
  echo
}

function is_array {
    if [ `declare -p $1 2> /dev/null | grep -q '^declare \-a'; echo $?` -eq 0 ]; then
        echo 1
    else
        echo 2
    fi
}

function dump_array_vals {
    array="${1}[@]"
    vals=''
    n=0 
    for x in ${!array}; do
        if [ $n -eq 0 ]; then vals='"'$x'"'
        else vals=$vals' "'$x'"'
        fi  
        n=$(($n + 1))
    done
    echo $vals
}

function save_usrvar {
    if [ "$1" == "" ]; then
        echo "You must supply a variable name for the first parameter of 'save_usrvar'!"
        exit 1
    fi
    if [ "${!1}" == "" ]; then
        echo "The variable you're saving with 'save_usrvar' must have a value!"
        exit 1
    fi
    if [ "$USRVARS" == "" ] || [ ! -d `dirname $USRVARS` ]; then
        echo
        echo "'USRVARS' is not set to a valid file! This is usually set in"
        echo "[cfx-server-admin]/shared-files/scripts/00-global-prelim.sh, so"
        echo "it's strange that it is no longer set.... Please look into this."
        echo
        exit 1
    fi

    if [ ! -f "$USRVARS" ]; then
        touch "$USRVARS"
    fi

    # If the variable hasn't already been set, set it
    if [ `cat "$USRVARS" | grep -c "^$1="` -eq 0 ] && [ `cat "$USRVARS" | grep -c "^declare -a $1="` -eq 0 ]; then
        if [ `is_array $1` -eq 1 ]; then
            echo "declare -a $1=(`dump_array_vals $1`)" >> $USRVARS
        else
            echo "$1="'"'"${!1}"'"' >> $USRVARS
        fi  

    # Otherwise, change its value
    else
        if [ `is_array $1` -eq 1 ]; then
            repl=`echo $(dump_array_vals $1) | sed -e 's/[]\\/$*.^|[]/\\\\&/g'`
            sed -i -E "s/^declare -a $1=.+$/declare -a $1=($repl)/" $USRVARS
        else
            repl=`echo ${!1} | sed -e 's/[]\\/$*.^|[]/\\\\&/g'`
            sed -i -E "s/^$1=.+$/$1="'"'"$repl"'"'"/" $USRVARS
        fi
    fi
}

if command -v readlink >/dev/null 2>&1; then
    resolver='readlink -f'
else
    if command -v realpath >/dev/null 2>&1; then
        resolver='realpath'
    else
        echo
        echo "ERROR: No readlink or realpath binaries found! Migrate-me requires"
        echo "one of these programs to resolve absolute URLs. Please figure out"
        echo "how to install one (preferrably readlink). Exiting :(."
        echo
        exit 1
    fi
fi










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
        CONFIG_DIR=`$resolver "$1"`
        shift
      else
        echo "No config directory specified, even though -c or --config-dir parameter passed!"
        exit 1
      fi
      ;;

    -p|--profile-dir)
      shift
      if test $# -gt 0; then
        PROFILE_DIR=`$resolver "$1"`
        shift
      else
        echo "No profile directory specified, even though -p or --profile-dir parameter passed!"
        exit 1
      fi
      ;;

    -v|--version)
      echo "$0 version $SCRIPT_VER"
      echo
      exit 0
      ;;

    *)
      if [ "${1:0:1}" == "-" ]; then
        echo 'Argument `'"$1"'` unknown!'
        echo_usage
        exit 1
      fi
      if [ "$PROFILE" != "" ]; then
        echo "You've passed two arguments that look like profiles. Please fix this. ('$PROFILE' and '$1')"
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
  CONFIG_DIR=`$resolver /etc/migrate-me`
fi
if [ "$PROFILE_DIR" == "" ]; then
  PROFILE_DIR="$CONFIG_DIR/profiles"
  DEFAULT_PRF_DIR=1
else
  DEFAULT_PRF_DIR=0
fi
while [ ! -d "$CONFIG_DIR" ]; do
  read -n 1 -p "Config dir '$CONFIG_DIR' doesn't exist. Would you like to create it? [Y,n] " ANS
  if [ "$ANS" != 'N' -a "$ANS" != 'n' ]; then
    mkdir -p "$CONFIG_DIR" 2>/dev/null
    if [ "$?" -gt 0 ]; then
        sudo mkdir -p "$CONFIG_DIR"
    fi
  else
    echo
    echo "Need a valid config directory to proceed"
    exit 1
  fi
done
if [ "$DEFAULT_PRF_DIR" -eq 1 ]; then
  if [ ! -d "$PROFILE_DIR" ]; then
    mkdir -p "$PROFILE_DIR" 2>/dev/null
    if [ "$?" -gt 0 ]; then
        sudo mkdir -p "$PROFILE_DIR"
        if [ "$?" -gt 0 ]; then
            echo "Couldn't create the profile directory '$PROFILE_DIR'. Exiting :("
            exit 1
        fi
    fi
  fi
else
  while [ ! -d "$PROFILE_DIR" ]; do
    read -n 1 -p "Profile dir '$PROFILE_DIR' doesn't exist. Would you like to create it? [Y,n] " ANS
    if [ "$ANS" != 'N' -a "$ANS" != 'n' ]; then
      mkdir -p "$PROFILE_DIR"
    else
      echo
      echo "Need a valid profile directory"
      exit 1
    fi
  done
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
# Prepare and export variables so other scripts can use them
#

CONFIG_DIR=`$resolver "$CONFIG_DIR"`
PROFILE_DIR=`$resolver "$PROFILE_DIR"`
SHARED_FILES=`$resolver "$SHARED_FILES"`
DONE_DIR=`$resolver "$DONE_DIR"`
USRVARS="$DONE_DIR/usr-vars.sh"
LOGFILE="$DONE_DIR/migrate-me.log"

export -f exit_on_fail
export -f save_usrvar
export -f is_array
export -f dump_array_vals
export -f lecho
export -f logme
export CONFIG_DIR
export PROFILE_DIR
export PROFILE
export SHARED_FILES
export DONE_DIR
export USRVARS
export LOGFILE
export resolver




lecho ""
lecho "**************************************************"
lecho "-- Welcome to the New System Migration console! --"
lecho "**************************************************"
lecho ""
lecho ":: Using profile '$PROFILE' ::"
lecho ""
lecho ""






# Run all scripts for given profile

current_dir=`pwd`
for script in "$PROFILE_DIR/$PROFILE/"*.sh ; do
  BASENM=`basename "$script"`
  if [[ "$BASENM" == *"-prelims.sh" ]] || [[ "$BASENM" == *"-cleanup.sh" ]] || [ ! -e "$DONE_DIR/$BASENM" ]; then
    lecho "Running $PROFILE/$BASENM...."
    . "$script"
    cd "$current_dir"
    lecho "Done."
    lecho ""
    touch "$DONE_DIR/$BASENM"
  else
    lecho "Already ran $PROFILE/$BASENM. Proceeding to next script."
  fi
done


lecho ""
lecho 'All scripts have been run. System should be ready to go!'
lecho ""
exit

