# bash auto completion for shibboleth
function _shibboleth_complete_options() {
  local curr_arg=${COMP_WORDS[COMP_CWORD]}
  local lines=$(echo "show|edit|diff|secure|version|help" | tr '|' '\n')
  COMPREPLY=( $(compgen -W '${lines[@]}' -- $curr_arg ) )
}
complete -F _shibboleth_complete_options shibboleth
