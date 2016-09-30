#!/bin/bash

# git stuff
GIT_PS1_SHOWDIRTYSTATE=yes
GIT_PS1_SHOWSTASHSTATE=yes
GIT_PS1_SHOWUNTRACKEDFILES=yes
GIT_PS1_SHOWCOLORHINTS=yes
GIT_PS1_SHOWUPSTREAM="auto verbose"
. $DOT_FILES_DIR/git/git-prompt.sh

##################################################
# The home directory (HOME) is replaced with a ~
# The last pwdmaxlen characters of the PWD are displayed
# Leading partial directory names are striped off
#   /home/me/stuff          -> ~/stuff                if USER=me
#   /usr/share/big_dir_name -> .../share/big_dir_name if pwdmaxlen=20
##################################################
function abbrev_pwd() {
    local lastExitStatus=$?

    # How many characters of the $PWD should be kept
    local pwdmaxlen=60
    # Indicate that there has been dir truncation
    local trunc_symbol="..."
    local dir=${PWD##*/}
    local pwdmaxlen=$(( ( pwdmaxlen < ${#dir} ) ? ${#dir} : pwdmaxlen ))
    local NEW_PWD=${PWD/#$HOME/\~}
    local pwdoffset=$(( ${#NEW_PWD} - pwdmaxlen ))
    if [ ${pwdoffset} -gt "0" ]
    then
        NEW_PWD=${NEW_PWD:$pwdoffset:$pwdmaxlen}
        NEW_PWD=${trunc_symbol}/${NEW_PWD#*/}
    fi

    echo $NEW_PWD
}

# echo out the current Ruby version, if we're in an rvm environment
function get_rvm_string() {
  if [[ "$(pwd)" == $HOME ]]; then # not interested if in homedir
    local rvmCurrent=""
  elif [[ "$rvm_ruby_string" != "" ]]; then
    # fast
    local rvmCurrent=$rvm_ruby_string
  elif [[ $(command -v ~/.rvm/bin/rvm-prompt) ]]; then
    # slow, sometimes necessary
    local rvmCurrent=$(~/.rvm/bin/rvm-prompt)
  fi

  if [[ "${rvmCurrent}" != "system" && "$rvmCurrent" != "" ]]; then
    # e.g. "(ruby-2.0.0)", with the name coloured
    echo " (${GREEN}${rvmCurrent}${RESTORE})"
  fi
}

# gets the current number of millis since the epoch.
# THIS DOESN'T WORK on normal mac. If it fails, check that gnubin is on the PATH
function current_time_millis() {
  echo $(($(date +%s%N)/1000000))
}
function command_timer_start() {
  local millis=$(current_time_millis)
  command_in_progress_timer=${command_in_progress_timer:-$millis}
}
function command_timer_stop() {
  local millis=$(current_time_millis)
  last_command_exec_time_secs=$(($millis - $command_in_progress_timer))
  unset command_in_progress_timer
}
function convert_time_string() {
  local total_millis="$1"
  ((total_secs=total_millis/1000))
  ((ms=total_millis%1000))
  ((s=total_secs%60))
  ((m=(total_secs%3600)/60))
  ((h=total_secs/3600))

  local time_string=""
  if   ((h>0)); then time_string="${h}h${m}m${s}s"
  elif ((m>0)); then time_string="${m}m${s}s"
  elif ((s>3)); then time_string="${s}s"
  elif ((s>0)); then time_string="${s}.$(printf "%0*d" 3 $ms | sed -e 's/[0]*$//g')s"
  else               time_string="${ms}ms"
  fi

  echo -n " in ${time_string}"

  # how do you do local vars on arithmetic?
  unset ms
  unset s
  unset m
  unset h
  unset total_secs
}
# prints out the execution time of the last command
function last_command_exec_time() {
  if [[ "$last_command_exec_time_secs" != "" ]]; then
    convert_time_string $last_command_exec_time_secs
  fi
}
# start the timer on each command
trap 'command_timer_start' DEBUG

function screen_command_exists() {
  [[ $(command -v screen) ]]
}
# gets the list of detached screen instances
function get_detached_screens() {
  local screens=$(screen_command_exists && screen -ls | grep Detached | awk '{ print $1 }' | sed "s/.$(hostname -s)//" | tr '\n' ',' | sed 's/,$//')
  if [[ "$screens" != "" ]]; then
    echo -n " (screens: $YELLOW$screens$RESTORE)"
  fi
}
function get_current_screen() {
  local screen=$(echo $STY | sed "s/.$(hostname -s)//")
  if [[ "$screen" != "" ]]; then
    echo -n " (in screen: $GREEN$screen$RESTORE)"
  fi
}
function tmux_command_exists() {
  [[ $(command -v tmux) ]]
}
# gets the list of detached tmux instances
function get_detached_tmuxs() {
  local tmuxs=$(tmux_command_exists && tmux ls 2>&1 | grep -v "no server running on" | grep -v "failed to connect to server" | grep -v "error connecting" | grep -v attached | sed -r 's/^([^:]+):.*/\1/' | tr '\n' ',' | sed 's/,$//')
  if [[ "$tmuxs" != "" ]]; then
    echo -n " (tmuxs: $YELLOW$tmuxs$RESTORE)"
  fi
}
function get_current_tmux() {
  local tmux=$(tmux_command_exists && tmux ls 2>&1 | grep -v "no server running on" | grep -v "failed to connect to server" | grep -v "error connecting" | grep attached | sed -r 's/^([^:]+):.*/\1/')
  if [[ "$tmux" != "" ]]; then
    echo -n " (in tmux: $GREEN$tmux$RESTORE)"
  fi
}

# print out the time zone of the current machine, in grey
function get_time_zone() {
  echo -n "\[$(tput sgr0)\]\[\033[38;5;7m\]"
  echo -n $(date +'%Z')
}

# if the last printed line did not end in a newline
# echo a marker character and a newline
function clear_line() {
  local curpos
  echo -en "\E[6n"

  # read current pos into variable
  IFS=";" read -sdR -a curpos

  ((curpos[1]!=1)) && \
    echo -e '\E[1m\E[41m\E[33m%\E[0m' # print marker, and newline
}

function containsRubyDirective() {
  grep -i -E -q -L "^(ruby \"\S+\"|#ruby=\S+)$" $1
}
function rvmHacks() {
  # HACK RVM tries to be clever with going back to the previous environment
  # on a directory change, but with multiple ruby projects on multiple versions
  # you end up with non-ruby directories getting a specifiv rvm-ruby version,
  # which is wierd. This is a way of disabling this behaviour - set this value
  # in every directory. Can't do this in the cd() function, because rvm has
  # taken over that as well!
  rvm_previous_environment="system"
}

function get_first_prompt_extras() {
  if [[ "$NUM_COMMANDS_THIS_SHELL" == "0" ]]; then
    echo "Using bash version [$BASH_VERSION] from [$BASH]\n"
  fi
}

NUM_COMMANDS_THIS_SHELL=0

function all_the_things() {
  local lastExitCode=$?

  command_timer_stop

  local startPromptAt=$(current_time_millis)

  clear_line
  shellTitle $(getExpectedHostname)

  rvmHacks

  local expectedHostNameAndOriginal=$(getExpectedHostnameAndOriginal)
  local apwd=$(abbrev_pwd)
  local rvm_string=$(get_rvm_string)
  local detached_screens=$(get_detached_screens)
  local current_screen=$(get_current_screen)
  local detached_tmuxs=$(get_detached_tmuxs)
  local current_tmux=$(get_current_tmux)
  local time_zone=$(get_time_zone)
  local first_prompt_extras=$(get_first_prompt_extras)

  local last_command_exec_time_string=$(last_command_exec_time)

  # prompt formatting helped by http://bashrcgenerator.com/
  __git_ps1 "${first_prompt_extras}\[\033[38;5;14m\]\u\[$(tput sgr0)\]\[\033[38;5;8m\]@\[$(tput sgr0)\]\[\033[38;5;5m\]${expectedHostNameAndOriginal}\[$(tput sgr0)\]\[\033[38;5;8m\]:\[$(tput sgr0)\]\[\033[38;5;14m\]${apwd}\[$(tput sgr0)\]\[\033[38;5;15m\]$RESTORE" "${rvm_string}${detached_screens}${current_screen}${detached_tmuxs}${current_tmux}\n\[$(tput sgr0)\]\[\033[38;5;10m\]\t\[$(tput sgr0)\]\[\033[38;5;15m\] ${time_zone} \[$(tput sgr0)\]\[\033[38;5;7m\](\[$(tput sgr0)\]\[\033[38;5;9m\]${lastExitCode}\[$(tput sgr0)\]\[\033[38;5;7m\]${last_command_exec_time_string})\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]\[\033[38;5;7m\]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"

  NUM_COMMANDS_THIS_SHELL=$((NUM_COMMANDS_THIS_SHELL=NUM_COMMANDS_THIS_SHELL+1))

  local endPromptAt=$(current_time_millis)
  ((prompt_creation_time_ms=endPromptAt-startPromptAt))
}

# don't export this
PROMPT_COMMAND=all_the_things