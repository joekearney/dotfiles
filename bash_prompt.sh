#!/bin/bash

# git stuff
GIT_PS1_SHOWDIRTYSTATE=yes
GIT_PS1_SHOWSTASHSTATE=yes
GIT_PS1_SHOWUNTRACKEDFILES=yes
GIT_PS1_SHOWCOLORHINTS=yes
GIT_PS1_SHOWUPSTREAM="auto verbose"
source ~/.git-prompt.sh

##################################################
# The home directory (HOME) is replaced with a ~
# The last pwdmaxlen characters of the PWD are displayed
# Leading partial directory names are striped off
#   /home/me/stuff          -> ~/stuff                if USER=me
#   /usr/share/big_dir_name -> .../share/big_dir_name if pwdmaxlen=20
##################################################
abbrev_pwd() {
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
rvm_string() {
  if [[ "${rvm_ruby_string}" != "" ]]; then
    # e.g. "(ruby-2.0.0)", with the name coloured
    echo " (\[$(tput sgr0)\]\[\033[38;5;10m\]${rvm_ruby_string}\[$(tput sgr0)\]\[\033[38;5;15m\])"
  fi
}

command_timer_start() {
  command_in_progress_timer=${command_in_progress_timer:-$SECONDS}
}
command_timer_stop() {
  last_command_exec_time_secs=$(($SECONDS - $command_in_progress_timer))
  unset command_in_progress_timer
}
# prints out the execution time of the last command
last_command_exec_time() {
  if ((last_command_exec_time_secs > 4)); then
    local total_secs=${last_command_exec_time_secs}
    local s = $((total_secs % 60))
    local m = $(( (total_secs % 3600) / 60))
    local h = $((total_secs / 3600))

    local time_string=""
    if   ((h > 0)); then time_string="${h}h${m}m${s}s"
    elif ((m > 0)); then time_string="${m}m${s}s"
    else                 time_string="${s}s"
    fi

    echo -n " in ${time_string}"
  fi
}
# start the timer on each command
trap 'command_timer_start' DEBUG

# print out the time zone of the current machine, in grey
time_zone() {
  echo -n "\[$(tput sgr0)\]\[\033[38;5;7m\]"
  echo -n $(date +'%Z')
}

# if the last printed line did not end in a newline
# echo a marker character and a newline
clear_line() {
  local curpos
  echo -en "\E[6n"

  # read current pos into variable
  IFS=";" read -sdR -a curpos

  ((curpos[1]!=1)) && \
    echo -e '\E[1m\E[41m\E[33m%\E[0m' # print marker, and newline
}

all_the_things() {
  command_timer_stop

  clear_line
  # prompt formatting helped by http://bashrcgenerator.com/
  __git_ps1 "\[\033[38;5;14m\]\u\[$(tput sgr0)\]\[\033[38;5;8m\]@\[$(tput sgr0)\]\[\033[38;5;5m\]\h\[$(tput sgr0)\]\[\033[38;5;8m\]:\[$(tput sgr0)\]\[\033[38;5;14m\]\$(abbrev_pwd)\[$(tput sgr0)\]\[\033[38;5;15m\]" "$(rvm_string)\n\[$(tput sgr0)\]\[\033[38;5;10m\]\t\[$(tput sgr0)\]\[\033[38;5;15m\] $(time_zone) \[$(tput sgr0)\]\[\033[38;5;7m\](\[$(tput sgr0)\]\[\033[38;5;9m\]\$?\[$(tput sgr0)\]\[\033[38;5;7m\]$(last_command_exec_time))\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]\[\033[38;5;7m\]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"
}

# don't export this
PROMPT_COMMAND=all_the_things
