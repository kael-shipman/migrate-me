# Migrate Me

_A simple script-based migration utility for *nix systems_

Migrate Me is a simple utility designed to allow users to maintain potentially complex reusable system configurations using just shell scripts. The shells scripts are named arbitrarily and stored in profile directories. There are no intended limitations on what they can do, though the recommendation is that they remain discrete units that can be rerun without damage.

Once each script finishes successfully, a file named after the script is stored in `$CONFIG_DIR/done/$PROFILE/`. On future runs, only scripts that are not recorded in this way will run, allowing the migration to pick up where it left off in case of errors.

You can also force individual scripts to run on demand by passing them directly to the command. Script names should be relative to the profile directory, meaning they should _include_ the profile name in them. (This is because each script is executed in isolation in the context of its profile, so each script needs to indicate which profile it's associated with.)

For example, suppose your profile directory is `~/migrate-me`, you have a profile called `home-pc` and in it a script called `05-user-setup.sh`. You can run `05-user-setup.sh` by calling `migrate-me.sh -p ~/migrate-me home-pc/05-user-setup.sh`. This will execute `05-user-setup.sh` in isolation, calling `*-prelims.sh` before, `*-cleanup.sh` after, and any `before` and `after` hooks set up for this script in the hooks directory.

## Installation

To install, simply download the [migrate-me.sh](https://github.com/kael-shipman/migrate-me/raw/master/migrate-me.sh) file and place it in your `PATH`. 

If you'd like to easily keep up with updates, you can clone this git repo and symlink the `migrate-me.sh` into your PATH. Optionally, you can `git checkout [tag]` in your repo clone to use a specific version.

Alternatively, you can use composer: `composer global require "kael-shipman/migrate-me ~2.2"` (though you might have to add it to your path, depending on how your Composer is set up).

On first run, it will ask you if you want to create the config directory (you should choose yes, or choose no and specify a different config directory using the command line options detailed below).

Also, you'll have to point it to your profiles. You can either put profiles into its default profile location (see below) or point it to your profile directory using the command line flag (see below).

## Profiles

The script is expected to be run with a specified profile, for example, `migrate-me.sh personal-computer`. If it's run without a profile specified (i.e., `migrate-me.sh`), it will attempt to find a default profile at `$PROFILE_DIR/default`. If you'd like, you can symlink `default` to your normal profile so that you can run the script frequently without specifying a profile (though I don't know why you would run it frequently).

The project has been created so that you can maintain a separate git repo of your profiles. See below for how to point the script to your profiles.

### Hooks

There are two special setup and teardown hook scripts that are intended to run before and after all other scripts, respectively. These are `*-prelims.sh` and `*-cleanup.sh` (usually called `000-prelims.sh` and `999-cleanup.sh`, but you can freely change the number of zeros and nines before each). You can include one, both, or neither -- it makes no difference. The `*-prelims.sh` script is useful for establishing configuration across all of the subsequent scripts. For example, you might create some functions and/or variables that all your scripts can access:

```bash
#!/bin/bash

export SERVER_NAME="test-server"
export WEB_DIR="/srv/www"
#...
```

The `*-cleanup.sh` script is intended to do what it says, and probably won't be used much, since there probably won't be much to cleanup.

You can also add `before` and `after` hooks for each of your scripts in the `$PROFILE_DIR/$PROFILE/hooks` folder. Assuming you have a script called `05-user-setup.sh`, if there is a file called `hooks/before-05-user-setup.sh`, it will be run before the script, and if there is a file called `after-05-user-setup.sh` it will be called after. It's typical to exclude the `hooks` directory from version control.

## Default Folders and Options to Override Them

There are four important directories that determine how `migrate-me` works. Two of them -- `$CONFIG_DIR` and `$PROFILE_DIR` can be overridden with command-line options.

### Config Dir

The config dir is where `migrate-me` stores any runtime files (usually on a per-user basis). For example, by default, this is the directory where it looks for profiles and the directory where it writes its records about which scripts have been run.

By default, this directory is `~/.config/migrate-me`. This can be overridden using the command line argument `-c` or `--config-dir`, each followed by a new directory.

### Profile Dir

This is where `migrate-me` looks for profiles. By default, it's located at `$CONFIG_DIR/profiles`. You can override this using the `-p` or `--profile-dir` arguments.

### Done Dir

This is an internal directory and there should be little reason to change it. Therefore, there is no command line option available to change it. It is the directory `$CONFIG_DIR/done`, and contains subfolders named for each profile that is run, which in turn contain files named for each script that has been successfully executed.

**Note:** To rerun scripts, just delete their marker files from the this directory.

There is no command-line option to override this.

### Shared Files Dir

This is another directory with little reason to be changed. It is expected to be found at `$PROFILE_DIR/shared-files`, beside the profile folders. Its purpose is to provide a common storage place within your profiles collection for configuration files that might be shared among profiles.

For example, many profiles might use the same `vimrc` file. You can reference this from within your scripts by putting `$SHARED_FILES/vimrc`.

There is no command-line option to override this.

## API

What I'm calling the "API" here is actually just a collection of pre-defined functions as variables that are available throughout the script.

### Global Variables

* **`$CONFIG_DIR`** -- The directory where configuration is stored (default: `/etc/migrate-me`)
* **`$PROFILE_DIR`** -- The directory where your profiles are stored (default: `$CONFIG_DIR/profiles`)
* **`$PROFILE`** -- The name of the profile currently in use (default: *passed from command line*)
* **`$SHARED_FILES`** -- The directory where you can keep files that you share between profiles (default: `$PROFILE_DIR/shared-files`)
* **`$DONE_DIR`** -- The directory where records of which files have been run are stored (default: `$CONFIG_DIR/done/$PROFILE`)
* **`$USERVARS`** -- The file where saved user variables are stored (default: `$DONE_DIR/usr-vars.sh`)
* **`$LOGFILE`** -- The file where each run's logs are written. (default: `$DONE_DIR/migrate-me.log`)

### Global Functions

* **`exit_on_fail(int exit_status, string fail_message)`** -- Exits, echoing the given message, if the first argument is greater than 0. For example, `exit_on_fail "$?" "Sorry, the command didn't end well"`
* **`save_usrvar(var-pointer variable_to_store)`** -- Saves a variable defined from user input for usage next time the script is run. Example: `if [ "$MYVAR" == "" ]; then MYVAR='my val'; save_usrvar MYVAR; fi`
* **`is_array(var-pointer variable_to_check)`** -- Checks to see if a given variable is an array.
* **`dump_array_vals(var-pointer array_to_dump)`** -- Dumps the values of an array enclosed in quotes. (This exists for use in `save_usrvar`)
* **`lecho(string string_to_echo)`** -- Echos a string and also logs it to `$LOGFILE`.
* **`logme(string string_to_log)`** -- Logs a string to `$LOGFILE`.

