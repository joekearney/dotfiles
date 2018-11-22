#!/bin/bash

DEBUG=no

function echoDebug() {
  if [[ "$DEBUG" == "yes" ]]; then
    echo "$@"
  fi
}

function repl() {
  local TEMPLATE="$DOT_FILES_DIR/sbt/build.sbt.template"
  local PROJECT_DIR="$HOME/.sbt-repl"

  echoDebug "Running sbt console in [$PROJECT_DIR] with template [$TEMPLATE]"
  local templateContent=$(cat $TEMPLATE | indent " |")
  echoDebug "$templateContent"

  echoDebug "Creating project dir [$PROJECT_DIR]"
  mkdir -p $PROJECT_DIR

  echoDebug "Copying template build file $TEMPLATE to $PROJECT_DIR/build.sbt"
  # copy template build.sbt, overwriting if exists
  cp $TEMPLATE $PROJECT_DIR/build.sbt

  local SBT_OPTS_FOR_REPL="-Xmx512M -XX:+UseG1GC -XX:+CMSClassUnloadingEnabled"
  echoDebug "Ready to start..."
  (echoDebug "Going to $PROJECT_DIR..." && \
    cd $PROJECT_DIR && \
    echoDebug "Running [SBT_OPTS=${SBT_OPTS_FOR_REPL} sbt console-quick]..." && \
    SBT_OPTS=${SBT_OPTS_FOR_REPL} sbt consoleQuick)
}
