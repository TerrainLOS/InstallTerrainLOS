#!/bin/bash

# exit immediately on undefined variable reference
set -u

# constants
CONTIKI_REPO="https://github.com/contiki-os/contiki"
TERRAIN_REPO="https://github.com/TerrainLOS/TerrainLOS"
USE_CUSTOM="Install an additional copy to a custom directory"
COOJA_CONF=~/.cooja.user.properties
HELP_FILE=HELP.txt

# default installation paths. these variables are subject to change
CONTIKI_PATH="$HOME/contiki"
TERRAIN_PATH="$HOME/TerrainLOS"

# silence these commands
pushd(){
  command pushd "$@" >/dev/null 2>&1
}
popd(){
  command popd "$@" >/dev/null 2>&1
}

log(){
  # print first argument to standard error
  echo ">>> $1" >&2
}

confirm(){
  # continually prompts for a "y" or "n" response until one is given.
  while :; do
    printf "$1 [y/n]? "
    read response
    test -z $response && continue
    test $response = "y" && return 0
    test $response = "n" && return 1
  done
}

prompt(){
  printf "$1: "
}

usable_path(){
  # checks that a directory exists and its writable
  if test ! -d "$1"; then
    log "ERROR: '$1' is not a directory"
    return 1
  fi

  if test ! -w "$1"; then
    log "ERROR: no permission to use '$1'"
    return 1
  fi

  return 0
}

get_contiki_path(){
  # exports CONTIKI_PATH by prompting for new path
  local new_path
  while :; do
    echo "Enter the path where contiki should be installed."
    echo "Leave blank to use default location [$HOME]."
    prompt "path"
    read new_path
    eval new_path=$new_path # required for tilde expansion

    test -z "$new_path" && new_path=$HOME
    usable_path "$new_path" || continue

    if grep -qs "$CONTIKI_REPO" $new_path/contiki/.git/config; then
      log "INFO: '$new_path/contiki' is already a contiki installation"
      echo "You can overwrite $new_path/contiki with a new installation."
      echo "Or you can choose not to, and be re-prompted for a new path."
      if confirm "overwrite $new_path/contiki"; then
        rm -rf $new_path/contiki
        break
      else
        continue
      fi
    fi

    break

  done

  CONTIKI_PATH="$new_path/contiki"
}

get_terrain_path(){
  # exports TERRAIN_PATH by prompting for a new path
  local new_path
  while :; do
    echo "Enter the path where TerrainLOS should be installed."
    echo "Leave blank to use default location [$HOME]."
    prompt "path"
    read new_path
    eval new_path=$new_path # required for tilde expansion

    test -z "$new_path" && new_path=$HOME
    usable_path "$new_path" || continue

    if grep -qs "$TERRAIN_REPO" $new_path/TerrainLOS/.git/config; then
      log "INFO: '$new_path/TerrainLOS' is already a TerrainLOS installation"
      echo "You can overwrite $new_path/TerrainLOS with a new installation."
      echo "Or you can choose not to, and be re-prompted for a new path."
      if confirm "overwrite $new_path/TerrainLOS"; then
        rm -rf $new_path/TerrainLOS
        break
      else
        continue
      fi
    fi
    break
  done
  TERRAIN_PATH="$new_path/TerrainLOS"
}

install_contiki(){
  log "WAIT: contiki is cloning to '$CONTIKI_PATH'"
  git clone -q $CONTIKI_REPO $CONTIKI_PATH
  log "INFO: contiki was successfully cloned"
}

install_terrain(){
  log "WAIT: TerrainLOS is cloning to '$TERRAIN_PATH'"
  git clone -q $TERRAIN_REPO $TERRAIN_PATH
  log "INFO: TerrainLOS was successfully cloned"
}

current_branch(){
  git branch | grep \* | cut -d ' ' -f2
}

get_branch(){
  pushd $CONTIKI_PATH
  log "ACTION: fetching latest contiki branches"
  git fetch -q
  BRANCH="$(current_branch)"
  if ! confirm "Would you like to use the current contiki branch [$BRANCH]"; then
    log "INFO: listing current contiki branches"
    git branch -a
    while :; do
      echo "Please enter a branch to use."
      echo "You can omit 'remotes/origin/' from the branch name."
      echo "Leave the branch blank to use the default [release-2-7]"
      prompt "branch"
      read BRANCH
      test -z $BRANCH && BRANCH='release-2-7'
      git show-ref -q $BRANCH && break
      log "ERROR: $BRANCH is not a valid branch"
    done
  fi
  popd
  log "INFO: using branch '$BRANCH'"
}

checkout_contiki(){
  pushd $CONTIKI_PATH
  log "ACTION: checking out contiki branch $BRANCH"
  git checkout -qf $BRANCH
  log "WAIT: initializing contiki submodules"
  git submodule update --init
  log "INFO: contiki submodules initialized"
  popd
}

checkout_terrain(){
  pushd $TERRAIN_PATH
  log "ACTION: checking out TerrainLOS branch $BRANCH"
  git checkout -qf $BRANCH
  popd
}

link_terrain(){
  local APPS_PATH=$CONTIKI_PATH/tools/cooja/apps
  if test -e $APPS_PATH/TerrainLOS; then
    log "INFO: TerrainLOS is already linked to cooja apps directory"
  else
    log "ACTION: linking $TERRAIN_PATH to cooja apps directory '$APPS_PATH'"
    ln -s $TERRAIN_PATH $APPS_PATH/TerrainLOS
  fi
}

register_terrain(){
  if test -f $COOJA_CONF; then
    log "ACTION: $COOJA_CONF exists, moving it to $COOJA_CONF.backup"
    mv $COOJA_CONF $COOJA_CONF.backup
#    if grep -q 'DEFAULT_PROJECTDIRS' $COOJA_CONF; then
#      if grep -q 'DEFAULT_PROJECTDIRS.*TerrainLOS' $COOJA_CONF; then
#        log "INFO: TerrainLOS is already registered"
#      else
#        log "ACTION: registering TerrainLOS as new extension"
#        if grep -q 'DEFAULT_PROJECTDIRS=$' $COOJA_CONF; then
#          sed -i '/^DEFAULT_PROJECTDIRS=/ s/$/[APPS_DIR]\/TerrainLOS/' $COOJA_CONF
#        else
#          sed -i '/^DEFAULT_PROJECTDIRS=/ s/$/;[APPS_DIR]\/TerrainLOS/' $COOJA_CONF
#        fi
#      fi
#    else
#      # cooja config exists, but DEFAULT_PROJECTDIRS option isn't present
#      echo "DEFAULT_PROJECTDIRS=[APPS_DIR]/TerrainLOS" >> $COOJA_CONF
#    fi
  else
    log "INFO: $COOJA_CONF does not exist"
  fi
  log "ACTION: initializing cooja extensions list with TerrainLOS"
  echo "DEFAULT_PROJECTDIRS=[APPS_DIR]/TerrainLOS" > $COOJA_CONF
}

build_terrain(){
  log "WAIT: TerrainLOS is building"
  local LOG=$TERRAIN_PATH/build.log
  pushd $TERRAIN_PATH
  COOJA_PATH=$CONTIKI_PATH/tools/cooja ant jar >$LOG 2>&1
  popd
  log "INFO: TerrainLOS finished building. View the log at $LOG"
}

test_terrain(){
  log "WAIT: TerrainLOS is being tested"
  local exit_code
  local LOG=$TERRAIN_PATH/test.log
  pushd $TERRAIN_PATH
  COOJA_PATH=$CONTIKI_PATH/tools/cooja ant test >$LOG 2>&1
  exit_code=$?
  popd
  log "INFO: TerrainLOS finished testing. View the log at $LOG"
  return $exit_code
}

main(){
  if grep -qs "$CONTIKI_REPO" "$CONTIKI_PATH/.git/config"; then
    log "INFO: contiki already installed at default location [$CONTIKI_PATH]"
    if confirm "$USE_CUSTOM"; then
      get_contiki_path
      mkdir "$CONTIKI_PATH"
      install_contiki
    fi
  else
    log "INFO: contiki is not installed at default location [$CONTIKI_PATH]"
    get_contiki_path
    mkdir -p "$CONTIKI_PATH"
    install_contiki
  fi

  if grep -qs "$TERRAIN_REPO" "$TERRAIN_PATH/.git/config"; then
    log "INFO: TerrainLOS already installed at default location [$TERRAIN_PATH]"
    if confirm "$USE_CUSTOM"; then
      get_terrain_path
      mkdir "$TERRAIN_PATH"
      install_terrain
    fi
  else
    log "INFO: TerrainLOS is not installed at default location [$TERRAIN_PATH]"
    get_terrain_path
    mkdir -p "$TERRAIN_PATH"
    install_terrain
  fi

  get_branch
  checkout_contiki
  checkout_terrain
  link_terrain
  register_terrain
  build_terrain
  if test_terrain; then
    log "INFO: All TerrainLOS tests passed"
  else
    log "LOG: TerrainLOS failed its tests"
  fi

  confirm "Would you like to view the help file" && cat $HELP_FILE
}

main
