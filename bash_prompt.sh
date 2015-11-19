#!/bin/bash

# git stuff
GIT_PS1_SHOWDIRTYSTATE=yes
GIT_PS1_SHOWSTASHSTATE=yes
GIT_PS1_SHOWUNTRACKEDFILES=yes
GIT_PS1_SHOWCOLORHINTS=yes
GIT_PS1_SHOWUPSTREAM="auto verbose"
. $DOT_FILES_DIR/git-prompt.sh

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
  if [[ $(command -v rvm) ]]; then
    local rvmCurrent=$(rvm current)
    if [[ "${rvmCurrent}" != "system" ]]; then
      # e.g. "(ruby-2.0.0)", with the name coloured
      echo " (${GREEN}${rvmCurrent}${RESTORE})"
    fi
  fi
}

# gets the current number of millis since the epoch.
# THIS DOESN'T WORK on normal mac. If it fails, check that gnubin is on the PATH
current_time_millis() {
  echo $(($(date +%s%N)/1000000))
}
command_timer_start() {
  local millis=$(current_time_millis)
  command_in_progress_timer=${command_in_progress_timer:-$millis}
}
command_timer_stop() {
  local millis=$(current_time_millis)
  last_command_exec_time_secs=$(($millis - $command_in_progress_timer))
  unset command_in_progress_timer
}
convert_time_string() {
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
last_command_exec_time() {
  if [[ "$last_command_exec_time_secs" != "" ]]; then
    convert_time_string $last_command_exec_time_secs
  fi
}
# start the timer on each command
trap 'command_timer_start' DEBUG

# gets the list of detached screen instances
detached_screens() {
  local screens=$(screen -ls | grep Detached | awk '{ print $1 }' | sed "s/.$(hostname -s)//" | tr '\n' ',' | sed 's/,$//')
  if [[ "$screens" != "" ]]; then
    echo -n " (screens: $YELLOW$screens$RESTORE)"
  fi
}
current_screen() {
  local screen=$(echo $STY | sed "s/.$(hostname -s)//")
  if [[ "$screen" != "" ]]; then
    echo -n " (in screen: $GREEN$screen$RESTORE)"
  fi
}

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
  local lastExitCode=$?

  command_timer_stop

  clear_line
  shellTitle $(getExpectedHostname)

  # HACK RVM tries to be clever with going back to the previous environment
  # on a directory change, but with multiple ruby projects on multiple versions
  # you end up with non-ruby directories getting a specifiv rvm-ruby version,
  # which is wierd. This is a way of disabling this behaviour - set this value
  # in every directory. Can't do this in the cd() function, because rvm has
  # taken over that as well!
  rvm_previous_environment="system"

  # prompt formatting helped by http://bashrcgenerator.com/
  __git_ps1 "\[\033[38;5;14m\]\u\[$(tput sgr0)\]\[\033[38;5;8m\]@\[$(tput sgr0)\]\[\033[38;5;5m\]\$(getExpectedHostnameAndOriginal)\[$(tput sgr0)\]\[\033[38;5;8m\]:\[$(tput sgr0)\]\[\033[38;5;14m\]\$(abbrev_pwd)\[$(tput sgr0)\]\[\033[38;5;15m\]$RESTORE" "$(rvm_string)$(detached_screens)$(current_screen)\n\[$(tput sgr0)\]\[\033[38;5;10m\]\t\[$(tput sgr0)\]\[\033[38;5;15m\] $(time_zone) \[$(tput sgr0)\]\[\033[38;5;7m\](\[$(tput sgr0)\]\[\033[38;5;9m\]${lastExitCode}\[$(tput sgr0)\]\[\033[38;5;7m\]$(last_command_exec_time))\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]\[\033[38;5;7m\]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"
}

# don't export this
PROMPT_COMMAND=all_the_things
