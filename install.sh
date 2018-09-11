#!/bin/bash

set -u

# constants
CONTIKI_REPO="https://github.com/contiki-os/contiki"
TERRAIN_REPO="https://github.com/TerrainLOS/TerrainLOS"
COOJA_CONF=~/.cooja.user.properties
COOJA_BIN=/usr/bin/cooja

if test "$USER" = "root"; then
  CONTIKI_PATH=/usr/share/contiki
  TERRAIN_PATH=/usr/share/TerrainLOS
else
  CONTIKI_PATH=/home/$USER/.local/share/contiki
  TERRAIN_PATH=/home/$USER/.local/share/TerrainLOS
fi

TERRAIN_JAR=$TERRAIN_PATH/lib/terrainlos.jar

log(){
  echo ">>> $1" >&2
}

check_step(){
  local EXIT_CODE=$1
  local MESSAGE=$2
  if test $EXIT_CODE -gt 0; then
    log "fail: $MESSAGE"
    exit 1
  else
    log "success: $MESSAGE"
  fi
}

get_contiki(){
  mkdir -p $CONTIKI_PATH
  check_step $? "create $CONTIKI_PATH"

  log "attempting to clone $CONTIKI_REPO..."
  git clone -q $CONTIKI_REPO $CONTIKI_PATH
  check_step $? "clone $CONTIKI_REPO to $CONTIKI_PATH"
}

get_terrain(){
  mkdir -p $TERRAIN_PATH
  check_step $? "create $TERRAIN_PATH"

  log "attempting to clone $TERRAIN_REPO..."
  git clone -q $TERRAIN_REPO $TERRAIN_PATH
  check_step $? "clone $TERRAIN_REPO to $TERRAIN_PATH"
}

checkout_contiki(){
  pushd $CONTIKI_PATH >/dev/null 2>&1

  git checkout -q release-2-7
  check_step $? "checkout contiki release 2.7"

  git submodule update --init
  check_step $? "initialize contiki submodules"

  popd >/dev/null 2>&1
}

build_terrain(){
  pushd $TERRAIN_PATH >/dev/null 2>&1

  log "attempting to build $TERRAIN_JAR..."
  COOJA_DIR=$CONTIKI_PATH/tools/cooja ant jar >/dev/null 2>&1
  check_step $? "build $TERRAIN_JAR"

  popd >/dev/null 2>&1
}

link_terrain(){
  ln -s $TERRAIN_PATH $CONTIKI_PATH/tools/cooja/apps/TerrainLOS
  check_step $? "link $TERRAIN_PATH to cooja apps"
}

register_terrain(){
  if test -f $COOJA_CONF; then
    # cooja config already exists, just modify it
    sed -i '/^DEFAULT_PROJECTDIRS=/ s/$/;[APPS_DIR]\/TerrainLOS/' $COOJA_CONF
    check_step $? "register TerrainLOS in existing cooja config"
  else
    # create config
    echo "DEFAULT_PROJECTDIRS=[APPS_DIR]/TerrainLOS" > $COOJA_CONF
    check_step $? "register TerrainLOS in new cooja config"
  fi
}


get_contiki
get_terrain
checkout_contiki
build_terrain
link_terrain
register_terrain
