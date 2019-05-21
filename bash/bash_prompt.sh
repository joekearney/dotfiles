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

    if [[ "$NEW_PWD" == "~" ]]; then
      echo "🏡"
    else
      echo $NEW_PWD
    fi
}

function getBatteryStatus() {
  if [[ "$(command -v battery)" ]]; then
    local value=$(battery)
    if [[ "${value}" != "" ]]; then
      echo "(🔋 ${value})"
    fi
  fi
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

function command_timer_start() {
  local millis=$(current_time_millis)
  command_in_progress_timer=${command_in_progress_timer:-$millis}
}
function command_timer_stop() {
  local end=$(current_time_millis)
  local start=${command_in_progress_timer:-0}

  if [[ "${start}" == "0" ]]; then
    # something broke, give up
    last_command_exec_time_secs=0
  else
    last_command_exec_time_secs=$((end - start))
    unset command_in_progress_timer
  fi
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
  local tmuxs=$(tmux_command_exists && tmux ls 2>&1 | grep -v "no server running on" | grep -v "failed to connect to server" | grep -v "error connecting" | grep -v "attached" | sed -r 's/^([^:]+):.*/\1/' | tr '\n' ',' | sed 's/,$//')
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

function last_line_col() {
  # curpos from https://stackoverflow.com/a/2575525

  # based on a script from http://invisible-island.net/xterm/xterm.faq.html
  exec < /dev/tty
  oldstty=$(stty -g)
  stty raw -echo min 0
  # on my system, the following line can be replaced by the line below it
  echo -en "\033[6n" > /dev/tty
  # tput u7 > /dev/tty    # when TERM=xterm (and relatives)
  IFS=';' read -r -d R -a pos
  stty $oldstty
  col=${pos[1]}

  echo $col
}

# if the last printed line did not end in a newline
# echo a marker character and a newline
function clear_line() {
  local curpos=$(last_line_col)

  local marker="<eol>"
  ((curpos!=1)) && \
    echo -e "\E[1m\E[41m\E[33m${marker}\E[0m" # print marker, and newline
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
    echo "Using bash [${YELLOW}$BASH${RESTORE}] version [${GREEN}$BASH_VERSION${RESTORE}]"
    echo "Using terminal [${YELLOW}${TERM_PROGRAM:-${TERMINAL_EMULATOR}}${RESTORE}] version [${GREEN}${TERM_PROGRAM_VERSION}${RESTORE}]"

    # need this because it goes in the prompt (!)
    # this is required because the iterm vars don't get set until late
    echo "\n"
  fi
}

NUM_COMMANDS_THIS_SHELL=0

function get_user_colour() {
  if [[ "$EUID" == "0" ]]; then
    echo "\[\033[38;5;1m\]"
  else
    echo "\[\033[38;5;14m\]"
  fi
}

function get_hg_prompt_string() {
  if ! command -v hg > /dev/null; then
    # no mercurial
    return
  fi

  if [ -z "$(hg root 2>/dev/null)" ]; then
    # no repo here
    return
  fi

  # Show * for modified files, + for added files, and % for untracked files.
  local hg_display_modifiers=""
  local hg_status_summary="$(hg status | cut -c 1)"
  if [[ "${hg_status_summary}" =~ .*M.* ]]; then
    hg_display_modifiers="${hg_display_modifiers}*"
  fi
  if [[ "${hg_status_summary}" =~ .*A.* ]]; then
    hg_display_modifiers="${hg_display_modifiers}+"
  fi
  if [[ "${hg_status_summary}" =~ .*\?.* ]]; then
    hg_display_modifiers="${hg_display_modifiers}%"
  fi
  if [[ "${hg_display_modifiers}" != "" ]]; then
    hg_display_modifiers=$(colorize "<light-red>${hg_display_modifiers}</light-red>")
  fi

  local hg_log_details=$(hg log -r . --template '{tags} {bookmarks}')

  colorize " (<green>${hg_log_details}</green> ${hg_display_modifiers})" | sed 's/  / /g'
}

function all_the_things() {
  local lastExitCode=$?

  command_timer_stop

  local startPromptAt=$(current_time_millis)

  clear_line

  rvmHacks

  local expectedHostNameAndOriginal=$(getExpectedHostnameAndOriginal)
  local batteryStatus=$(getBatteryStatus)
  local apwd=$(abbrev_pwd)
  local rvm_string=$(get_rvm_string)
  local hg_string=$(get_hg_prompt_string)
  local detached_screens=$(get_detached_screens)
  local current_screen=$(get_current_screen)
  local detached_tmuxs=$(get_detached_tmuxs)
  local current_tmux=$(get_current_tmux)
  local time_zone=$(get_time_zone)
  local first_prompt_extras=$(get_first_prompt_extras)

  local last_command_exec_time_string=" in $(last_command_exec_time)"

  local user_colour=$(get_user_colour)

  # if we're remote, add a prefix
  local shellPrefix=""
  if [ -z ${SSH_CONNECTION+x} ]; then
    # variable is unset, we are not connected over SSH
    shellPrefix=""
  else
    shellPrefix="☎️:"
  fi

  shellTitle "${shellPrefix}$(basename "${apwd}")"

  # prompt formatting helped by http://bashrcgenerator.com/
  __git_ps1 "${first_prompt_extras}${user_colour}\u\[$(tput sgr0)\]\[\033[38;5;8m\]@\[$(tput sgr0)\]\[\033[38;5;5m\]${expectedHostNameAndOriginal}\[$(tput sgr0)\]${batteryStatus}\[\033[38;5;8m\]:\[$(tput sgr0)\]\[\033[38;5;14m\]${apwd}\[$(tput sgr0)\]\[\033[38;5;15m\]$RESTORE" "${hg_string}${rvm_string}${detached_screens}${current_screen}${detached_tmuxs}${current_tmux}\n\[$(tput sgr0)\]\[\033[38;5;10m\]\t\[$(tput sgr0)\]\[\033[38;5;15m\] ${time_zone} \[$(tput sgr0)\]\[\033[38;5;7m\](\[$(tput sgr0)\]\[\033[38;5;9m\]${lastExitCode}\[$(tput sgr0)\]\[\033[38;5;7m\]${last_command_exec_time_string})\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]\[\033[38;5;7m\]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"

  NUM_COMMANDS_THIS_SHELL=$((NUM_COMMANDS_THIS_SHELL=NUM_COMMANDS_THIS_SHELL+1))

  local endPromptAt=$(current_time_millis)
  ((prompt_creation_time_ms=endPromptAt-startPromptAt))
}

# don't export this
PROMPT_COMMAND=all_the_things
