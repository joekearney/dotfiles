# bash completion for tmux
# Written by Oystein Steimler <oystein@nyvri.net>
#
# $ sudo cp tmux-completion.bash /etc/bash_completion.d/tmux
# $ . /etc/bash_completion.d/tmux
#

_sessions() {
  SESSIONS=`tmux ls -F#{session_name} | xargs echo`
}

_tmux() {
  local cur prev comp
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  case "$prev" in
    attach)
      comp="-t"
      ;;
    -t)
      _sessions
      comp="$SESSIONS"
      ;;
    tmux)
      comp="attach detatch ls new"
      ;;
  esac

  COMPREPLY=( $(compgen -W "${comp}" -- ${cur}) )
  return 0
}

complete -F _tmux tmux
