function tunnelblick() {
  local op=$1
  if [[ "$op" == "restart" ]]; then
    osascript $DOT_FILES_DIR/tunnelblick/tunnelblick-restart.scpt
  elif [[ "$op" == "stop" ]]; then
    osascript $DOT_FILES_DIR/tunnelblick/tunnelblick-stop.scpt
  elif [[ "$op" == "kill" ]]; then
    ps -e -o pid,comm | grep -i tunnelblick | awk '{print $1}' | xargs -n 1 sudo kill
  elif [[ "$op" == "status" ]]; then
    osascript $DOT_FILES_DIR/tunnelblick/tunnelblick-status.scpt
  elif [[ "$op" == "env" ]]; then
    echo "Primary vpn:        [$PRIMARY_TUNNELBLICK_VPN_NAME]"
    echo "Validation address: [$TUNNELBLICK_VALIDATE_ADDRESS]"
    echo "Current status:     [$(tunnelblick status)]"
  elif [[ "$op" == "check" ]]; then
    if [[ $(tunnelblick status) == "CONNECTED" ]]; then
      echo "Tunnelblick thinks it is connected to [$PRIMARY_TUNNELBLICK_VPN_NAME]"
      if [[ $TUNNELBLICK_VALIDATE_ADDRESS ]]; then
        echo "Testing connection to [$TUNNELBLICK_VALIDATE_ADDRESS]..."
        host $TUNNELBLICK_VALIDATE_ADDRESS > /dev/null
        local validateExitCode=$?
        if [[ "$validateExitCode" != "0" ]]; then
          echo "Failed to resolve validation host [$TUNNELBLICK_VALIDATE_ADDRESS], restarting tunnelblick..."
          tunnelblick restart
        else
          echo "Succeeded resolving validation host [$TUNNELBLICK_VALIDATE_ADDRESS], connection to [$PRIMARY_TUNNELBLICK_VPN_NAME] seems good."
        fi
      fi
    else
      echo "Tunnelblick not connected, restarting..."
      tunnelblick restart
    fi
  else
    echo "Usage: ${FUNCNAME[0]} restart|stop|kill|status|env|check"
    echo "Useful environment variables:"
    echo "    PRIMARY_TUNNELBLICK_VPN_NAME - the name of the VPN to which to connect"
    echo "    TUNNELBLICK_VALIDATE_ADDRESS - an address of something on the network that can only be resolved on the VPN"
    return 1
  fi
}
# bash auto completion for cdg
function _tunnelblick_complete_options() {
  local curr_arg=${COMP_WORDS[COMP_CWORD]}
  local lines=$(echo "restart|stop|kill|status|env|check" | tr '|' '\n')
  COMPREPLY=( $(compgen -W '${lines[@]}' -- $curr_arg ) )
}
complete -F _tunnelblick_complete_options tunnelblick
