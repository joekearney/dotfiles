# bash auto completion for shibboleth
function _shibboleth_complete_options() {
  local curr_arg=${COMP_WORDS[COMP_CWORD]}
  if [[ "$COMP_CWORD" == "1" ]]; then
    local lines=$(echo "show|edit|diff|secure|version|help" | tr '|' '\n')
    COMPREPLY=( $(compgen -W '${lines[@]}' -- $curr_arg ) )
  else
    COMPREPLY=( $(compgen -f -- $curr_arg ) )
  fi
}
complete -F _shibboleth_complete_options -o filenames shibboleth
