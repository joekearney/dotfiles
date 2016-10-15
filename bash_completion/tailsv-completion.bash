# bash auto completion for tailsv
function _tailsv_complete_options() {
  local curr_arg=${COMP_WORDS[COMP_CWORD]}
  if [[ "$COMP_CWORD" == "1" ]]; then
    local lines=$(ls /etc/sv/)
    COMPREPLY=( $(compgen -W '${lines[@]}' -- $curr_arg ) )
  fi
}
complete -F _tailsv_complete_options tailsv
