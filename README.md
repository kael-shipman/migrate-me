# Migrate Me

_A simple script-based migration utility for *nix systems_

Migrate Me is a simple utility designed to allow users to maintain potentially complex reusable system configurations using just shell scripts. The shells scripts are named arbitrarily and stored in profile directories. There are no intended limitations on what they can do, though the recommendation is that they remain discrete units that can be rerun without damage.

Once each script finishes successfully, a file named after the script is stored in `$CONFIG_DIR/done/$PROFILE/`. On future runs, only scripts that are not recorded in this way will run, allowing the migration to pick up where it left off in case of errors.

## Installation

To install, just symlink `migrate-me.sh` to any of your `bin` directories (e.g., `/usr/local/bin/` or `/usr/bin/`). You can then call it from anywhere by simply typing `migrate-me.sh`.

Of course, you can also use it locally by entering the migrate-me folder and typing `./migrate-me.sh`.

On first run, it will ask you if you want to create the config directory (you should choose yes, or choose no and specify a different config directory using the command line options detailed below).

Also, you'll have to point it to your profiles. You can either put profiles into its default profile location (see below) or point it to your profile directory using the command line flag (see below).

## Profiles

The script is expected to be run with a specified profile, for example, `migrate-me.sh personal-computer`. If it's run without a profile specified (i.e., `migrate-me.sh`), it will attempt to find a default profile at `$PROFILE_DIR/default`. If you'd like, you can symlink `default` to your normal profile so that you can run the script frequently without specifying a profile (though I don't know why you would run it frequently).

The project has been created so that you can maintain a separate git repo of your profiles. See below for how to point the script to your profiles.

### Special Hooks

There are two special setup and teardown "hook" scripts that are intended to before and after all other scripts, respectively. These are `00-prelims.sh` and `99-cleanup.sh`. You can include one, both, or neither -- it makes no difference. The `00-prelims.sh` script is useful for establishing configuration across all of the subsequent scripts. For example, you might create some functions and/or variables that all your scripts can access:

```bash
#!/bin/bash

export SERVER_NAME="test-server"
export WEB_DIR="/srv/www"
#...
```

The `99-cleanup.sh` script is intended to do what it says, and probably won't be used much, since there probably won't be much to cleanup.

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

