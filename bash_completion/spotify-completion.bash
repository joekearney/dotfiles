# bash auto completion for `brew install spotify`
function _spotify_complete_options() {
  local curr_arg=${COMP_WORDS[COMP_CWORD]}
  if [[ "$COMP_CWORD" == "1" ]]; then
    local lines=$(echo "play|pause|next|prev|pos|quit|status" | tr '|' '\n')
    COMPREPLY=( $(compgen -W '${lines[@]}' -- $curr_arg ) )
  else
    COMPREPLY=( $(compgen -f -- $curr_arg ) )
  fi
}
complete -F _spotify_complete_options spotify
