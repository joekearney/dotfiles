#!/bin/bash

# git stuff
GIT_PS1_SHOWDIRTYSTATE=yes
GIT_PS1_SHOWSTASHSTATE=yes
GIT_PS1_SHOWUNTRACKEDFILES=yes
GIT_PS1_SHOWCOLORHINTS=yes
GIT_PS1_SHOWUPSTREAM="auto verbose"
loadIfExists $DOT_FILES_DIR/git/git-prompt.sh

##################################################
# The home directory (HOME) is replaced with a ~
# The last pwdmaxlen characters of the PWD are displayed
# Leading partial directory names are striped off
#   /home/me/stuff          -> ~/stuff                if USER=me
#   /usr/share/big_dir_name -> .../share/big_dir_name if pwdmaxlen=20
##################################################
function abbrev_pwd() {
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
  if [ -z ${command_in_progress_timer+x} ]; then
    local millis
    millis=$(current_time_millis)
    command_in_progress_timer=${command_in_progress_timer:-$millis}
  fi
}
function command_timer_stop() {
  local end
  end=$(current_time_millis)
  local start=${command_in_progress_timer:-0}

  if [[ "${start}" == "0" ]]; then
    # something broke, give up
    last_command_exec_time_secs=0
  else
    last_command_exec_time_secs=$((end - start))
  fi
  unset command_in_progress_timer
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

function get_first_prompt_extras() {

    local hostDeclaration="On:         host[$(hostname -f | sed -E "s/([^.]+)(.*)/${GREEN}\1${RESTORE}\2/")]"
    local all_bits="Using:      bash[${YELLOW}${BASH}${RESTORE}]"
    if ! [ -z "${BASH_VERSION}" ]; then
      all_bits="${all_bits} version[${GREEN}${BASH_VERSION}${RESTORE}]"
    fi

    local some_terminal_info="${TERM_PROGRAM:-${TERMINAL_EMULATOR:-${TERM}}}"
    if ! [ -z "${BASH_VERSION}" ]; then
      all_bits="${all_bits} terminal[${YELLOW}${some_terminal_info}${RESTORE}]"
      if ! [ -z "${TERM_PROGRAM_VERSION}" ]; then
        all_bits="${all_bits} version[${GREEN}${TERM_PROGRAM_VERSION}${RESTORE}]"
      fi
    fi

    echo "${hostDeclaration}"
    echo "${all_bits}"
    echo ""
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

  local hg_display_modifiers=""
  local hg_status_summary
  hg_status_summary="$(hg status | cut -c 1 | uniq | tr -d '\n')"
  if [[ "${hg_status_summary}" != "" ]]; then
    hg_display_modifiers=" <light-red>${hg_status_summary}</light-red>"
  fi

  local hg_log_details
  hg_log_details=$(hg log -r . --template "{p4head} current[{clnames}] willUpdate[{willupdatecl}]" | \
    sed -E 's/[^ ]*\[\]//g' | \
    sed -E 's/(^[ ]*|[ ]+$)//g' | \
    sed 's/  / /g' | \
    sed 's|\[|\[<none>|g' | sed 's|\]|</none>\]|g')

  colorize " (<green>${hg_log_details}</green>${hg_display_modifiers})"
}

function all_the_things() {
  local lastExitCode=$?

#  if [[ "$NUM_COMMANDS_THIS_SHELL" != "0" ]]; then
#    clear_line
#  fi

  local batteryStatus=$(getBatteryStatus)
  local hostname=$(hostname -s)
  local apwd=$(abbrev_pwd)

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
  __git_ps1 "${user_colour}\u\[$(tput sgr0)\]\[\033[38;5;8m\]@\[$(tput sgr0)\]\[\033[38;5;5m\]${hostname}\[$(tput sgr0)\]${batteryStatus}\[\033[38;5;8m\]:\[$(tput sgr0)\]\[\033[38;5;14m\]${apwd}\[$(tput sgr0)\]\[\033[38;5;15m\]$RESTORE" "\n\[$(tput sgr0)\]\[\033[38;5;10m\]\t\[$(tput sgr0)\]\[\033[38;5;15m\] ${time_zone} \[$(tput sgr0)\]\[\033[38;5;7m\](\[$(tput sgr0)\]\[\033[38;5;9m\]${lastExitCode}\[$(tput sgr0)\]\[\033[38;5;7m\]${last_command_exec_time_string})\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]\[\033[38;5;7m\]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"

  NUM_COMMANDS_THIS_SHELL=$((NUM_COMMANDS_THIS_SHELL=NUM_COMMANDS_THIS_SHELL+1))

  local endPromptAt=$(current_time_millis)
  ((prompt_creation_time_ms=endPromptAt-startPromptAt))
}

get_first_prompt_extras

if [[ "${TERM_PROGRAM:-${TERMINAL_EMULATOR}}" == "WarpTerminal" ]]; then
  echo "Skipping fancy prompt"
  # PS1="${user_colour}\u\[$(tput sgr0)\]\[\033[38;5;8m\]@\[$(tput sgr0)\]\[\033[38;5;5m\]$(hostname -s)\[$(tput sgr0)\]$(getBatteryStatus)\[\033[38;5;8m\]:\[$(tput sgr0)\]\[\033[38;5;14m\]$(abbrev_pwd)\[$(tput sgr0)\]\[\033[38;5;15m\]$RESTORE \[$(tput sgr0)\]\[\033[38;5;10m\]\t\[$(tput sgr0)\]\[\033[38;5;15m\] $(get_time_zone) \[$(tput sgr0)\]"
else
  # don't export this
  PROMPT_COMMAND=all_the_things

  . "$DOT_FILES_DIR/bash/bash-preexec.sh"

  function preexec_start_timer() { command_timer_start; }
  preexec_functions+=(preexec_start_timer)

  function precmd_stop_timer() { command_timer_stop; }
  precmd_functions+=(precmd_stop_timer)
fi
