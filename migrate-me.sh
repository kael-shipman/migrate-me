#!/bin/bash

export SCRIPT_VER=2.3

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
  echo "$0 [options] profile|script[ script....]"
  echo
  echo "Options:"
  echo "  -h, --help                      show this help"
  echo "  -p [dir], --profile-dir [dir]   set the directory in which to find profiles"
  echo "  -c [dir], --config-dir [dir]    set the directory in which to find migrate-me config"
  echo
  echo "If passing individual scripts, they should be relative to the profile directory (that is, the"
  echo "scriptname passed should INCLUDE the profile directory). When running scripts, the \*-prelims.sh"
  echo "file for each script profile (the directory preceding the actually script name) will be run"
  echo "every time the script is run. As such, each script executes as an isolated unit between \*-prelims.sh"
  echo "and \*-cleanup.sh"
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
            sed -i -E "s/^$1=.*$/$1="'"'"$repl"'"'"/" $USRVARS
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
declare -a SCRIPTS

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
      SCRIPTS[${#SCRIPTS[@]}]=$1
      shift
      ;;

  esac
done




#
# Validate parameters
#

if [ "$CONFIG_DIR" == "" ]; then
  CONFIG_DIR="/etc/migrate-me"
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

if [ "${#SCRIPTS[@]}" -eq 0 ]; then
  if [ ! -d "$PROFILE_DIR/default" ]; then
    echo "You haven't provided a profile and there is no default profile available in '$PROFILE_DIR'. If you'd like to create a default profile, create a symlink or folder called 'default' under the profile directory '$PROFILE_DIR'."
    echo_usage
    exit 1
  else
    PROFILE=$(basename "`$resolver "$PROFILE_DIR/default"`")
    SCRIPTS=''
    echo "Using default profile '$PROFILE'."
  fi
elif [ "${#SCRIPTS[@]}" -eq 1 ] && [ -d "$PROFILE_DIR/${SCRIPTS[0]}" ]; then
  PROFILE="${SCRIPTS[0]}"
  SCRIPTS=''
fi

if [ ! -z "$SCRIPTS" ]; then
  for s in ${SCRIPTS[@]}; do
    if [ ! -f "$PROFILE_DIR/$s" ]; then
      echo "It looks like you're trying to execute specific scripts, but you've passed a filename ('$s') that either doesn't exist or isn't a script. Please try again."
      echo_usage
      exit 1
    fi
  done
fi



#
# Prepare and export variables so other scripts can use them
#


SHARED_FILES="$PROFILE_DIR/shared-files"
DONE_DIR="$CONFIG_DIR/done/$PROFILE"
USRVARS="$DONE_DIR/usr-vars.sh"
LOGFILE="$DONE_DIR/migrate-me.log"
mkdir -p "$DONE_DIR"

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



current_dir=`pwd`
if [ ! -z "$PROFILE" ]; then

  lecho ""
  lecho "**************************************************"
  lecho "-- Welcome to the New System Migration console! --"
  lecho "**************************************************"
  lecho ""
  lecho ":: Using profile '$PROFILE' ::"
  lecho ""
  lecho ""
  
  # Run all scripts for given profile
  
  for script in "$PROFILE_DIR/$PROFILE/"*.sh ; do
    BASENM=`basename "$script"`
    if [[ "$BASENM" == *"-prelims.sh" ]] || [[ "$BASENM" == *"-cleanup.sh" ]] || [ ! -e "$DONE_DIR/$BASENM" ]; then
      lecho "Running $PROFILE/$BASENM...."
      if [ -e "$PROFILE_DIR/$PROFILE/hooks/before-$BASENM" ]; then
          lecho "Before hook found! Running..."
          . "$PROFILE_DIR/$PROFILE/hooks/before-$BASENM"
          lecho "Done with before hook"
      fi
  
      . "$script"
      cd "$current_dir"
  
      if [ -e "$PROFILE_DIR/$PROFILE/hooks/after-$BASENM" ]; then
          lecho "After hook found! Running..."
          . "$PROFILE_DIR/$PROFILE/hooks/after-$BASENM"
          lecho "Done with after hook"
      fi
      lecho "Done with $script."
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

else
  
  lecho
  lecho
  lecho "**********************************************"
  lecho "--         Welcome to Migrate Me            --"
  lecho "**********************************************"
  lecho
  lecho ":: Running individual scripts ::"
  lecho
  lecho

  dd="$DONE_DIR"
  for script in ${SCRIPTS[@]}; do
    PROFILE=`dirname "$script"`
    DONE_DIR=`$resolver "$DONE_DIR/$PROFILE"`
    mkdir -p "$DONE_DIR"
    USRVARS="$DONE_DIR/usr-vars.sh"
    LOGFILE="$DONE_DIR/migrate-me.log"
    BASENM=`basename "$script"`

    # Run prelims
    if [ -e "$PROFILE_DIR/$PROFILE/"*-prelims.sh ]; then
        . "`$resolver "$PROFILE_DIR/$PROFILE/"*-prelims.sh`"
    fi

    lecho "Running $PROFILE/$BASENM...."

    if [ -e "$PROFILE_DIR/$PROFILE/hooks/before-$BASENM" ]; then
        lecho "Before hook found! Running..."
        . "$PROFILE_DIR/$PROFILE/hooks/before-$BASENM"
        lecho "Done with before hook"
    fi

    . "$script"
    cd "$current_dir"

    if [ -e "$PROFILE_DIR/$PROFILE/hooks/after-$BASENM" ]; then
        lecho "After hook found! Running..."
        . "$PROFILE_DIR/$PROFILE/hooks/after-$BASENM"
        lecho "Done with after hook"
    fi
    lecho "Done with $script."
    lecho 

    # Run cleanup
    if [ -e "$PROFILE_DIR/$PROFILE/"*-cleanup.sh ]; then
        . "`$resolver "$PROFILE_DIR/$PROFILE/"*-cleanup.sh`"
    fi
  done
fi


