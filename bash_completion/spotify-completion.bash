# bash auto completion for `brew install spotify`
function _spotify_complete_options() {
  local curr_arg=${COMP_WORDS[COMP_CWORD]}
  if [[ "$COMP_CWORD" == "1" ]]; then
    local lines=$(echo "play|pause|next|prev|pos|quit|status|toggle" | tr '|' '\n')
    COMPREPLY=( $(compgen -W '${lines[@]}' -- $curr_arg ) )
  elif [[ "$COMP_CWORD" == "2" ]]; then
    local prev=${COMP_WORDS[COMP_CWORD - 1]}
    local lines
    case ${prev} in
      toggle )
        lines=$(echo "shuffle|repeat" | tr '|' '\n')
        ;;
      vol )
        lines=$(echo "up|down|show" | tr '|' '\n')
        ;;
      play )
        lines=$(echo "album|artist|list" | tr '|' '\n')
        ;;
    esac

    COMPREPLY=( $(compgen -W '${lines[@]}' -- $curr_arg ) )
  else
    COMPREPLY=( $(compgen -f -- $curr_arg ) )
  fi
}
complete -F _spotify_complete_options spotify
