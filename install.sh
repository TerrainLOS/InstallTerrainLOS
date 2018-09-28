#!/bin/bash

# exit immediately on undefined variable reference
set -u

# constants
CONTIKI_REPO="https://github.com/contiki-os/contiki"
TERRAIN_REPO="https://github.com/TerrainLOS/TerrainLOS"
USE_CUSTOM="Would you like to use a custom contiki directory"
COOJA_CONF=~/.cooja.user.properties
HELP_FILE=HELP.txt

# the default contiki installation path. this variable is subject to change
CONTIKI_PATH="$HOME/contiki"

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

valid_contiki(){
  # checks that the remote origin url of a git repo matches contiki's repo url
  test -d $1 || return 1
  pushd "$1"
  local REMOTE_ORIGIN_URL="$(git config --get remote.origin.url)"
  popd
  test "$REMOTE_ORIGIN_URL" = "$CONTIKI_REPO"
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
    prompt "Please enter the path where contiki should be installed"
    read new_path
    eval new_path=$new_path # required for tilde expansion

    test -z "$new_path" && continue
    usable_path "$new_path" || continue

    if test -d $new_path/contiki; then
      log "ERROR: '$new_path/contiki' is already a contiki installation"
      continue
    fi

    # all checks passed, so new_path is valid
    break

  done

  CONTIKI_PATH="$new_path/contiki"
}

get_terrain_path(){
  # exports TERRAIN_PATH by prompting for a new path
  local new_path
  while :; do
    prompt "Please enter the path where TerrainLOS should be installed"
    read new_path
    eval new_path=$new_path # required for tilde expansion

    test -z "$new_path" && continue
    usable_path "$new_path" || continue

    if test -d $new_path/TerrainLOS; then
      log "ERROR: '$new_path/TerrainLOS' is already a TerrainLOS installation"
      continue
    fi
    break
  done
  TERRAIN_PATH="$new_path/TerrainLOS"
}

install_contiki(){
  log "Please wait while contiki is installed to '$CONTIKI_PATH'"
  git clone -q $CONTIKI_REPO $CONTIKI_PATH
}

install_terrain(){
  log "Please wait while TerrainLOS is installed to '$TERRAIN_PATH'"
  git clone -q $TERRAIN_REPO $TERRAIN_PATH
}

current_branch(){
  git branch | grep \* | cut -d ' ' -f2
}

get_branch(){
  pushd $CONTIKI_PATH
  BRANCH="$(current_branch)"
  if ! confirm "Would you like to use the current contiki branch [$BRANCH]"; then
    git branch -a
    while :; do
      prompt "Please enter a branch to use"
      read BRANCH
      git show-ref -q $BRANCH && break
      log "ERROR: $BRANCH is not a valid branch"
    done
  fi
  popd
  log "Using branch '$BRANCH'"
}

checkout_contiki(){
  pushd $CONTIKI_PATH
  git checkout -q $BRANCH
  git submodule update --init
  popd
}

checkout_terrain(){
  pushd $TERRAIN_PATH
  git checkout -q $BRANCH
  popd
}

link_terrain(){
  ln -s $TERRAIN_PATH $CONTIKI_PATH/tools/cooja/apps/TerrainLOS
}

register_terrain(){
  if test -f $COOJA_CONF; then
    # cooja config already exists, just modify it
    sed -i '/^DEFAULT_PROJECTDIRS=/ s/$/;[APPS_DIR]\/TerrainLOS/' $COOJA_CONF
  else
    # create config
    echo "DEFAULT_PROJECTDIRS=[APPS_DIR]/TerrainLOS" > $COOJA_CONF
  fi
}

build_terrain(){
  pushd $TERRAIN_PATH
  COOJA_PATH=$CONTIKI_PATH/tools/cooja ant jar >/dev/null 2>&1
  popd
}

test_terrain(){
  local exit_code
  pushd $TERRAIN_PATH
  COOJA_PATH=$CONTIKI_PATH/tools/cooja ant test >/dev/null 2>&1
  exit_code=$?
  popd
  return exit_code
}

main(){
  if valid_contiki "$CONTIKI_PATH"; then
    log "contiki already installed at default location: '$CONTIKI_PATH'"
    if confirm "$USE_CUSTOM"; then
      get_contiki_path
      mkdir "$CONTIKI_PATH"
      install_contiki
    fi
  else
    log "contiki is not installed at default location: '$CONTIKI_PATH'"
    get_contiki_path
    mkdir "$CONTIKI_PATH"
    install_contiki
  fi

  get_terrain_path
  install_terrain
  get_branch
  checkout_contiki
  checkout_terrain
  link_terrain
  register_terrain
  build_terrain
  if test_terrain; then
    log "All TerrainLOS tests passed"
  else
    log "TerrainLOS failed its tests"
  fi

  confirm "Would you like to view the help file" && cat $HELP_FILE
}

main
