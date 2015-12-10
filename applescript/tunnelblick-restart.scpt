tell application "Tunnelblick"
    set vpnName to (system attribute "PRIMARY_TUNNELBLICK_VPN_NAME")
    if vpnName = ""
        log "Set the environment variable PRIMARY_TUNNELBLICK_VPN_NAME to the name of the network you want to restart"
        error number -128
    end if
    get state of first configuration where name = vpnName
    set tbstate to result
    log (vpnName & " is currently in state [" & tbstate & "]")

    if tbstate is not "SLEEP" and tbstate is not "EXITING" then
        log "Disconnecting now..."
        disconnect vpnName

        get state of first configuration where name = vpnName
        repeat until result = "SLEEP" or result = "EXITING"
            log (vpnName & " is in state [" & result & "]. Trying again...")
            delay 1
            get state of first configuration where name = vpnName
        end repeat
    end if

    log (vpnName & " is currently disconnected. Reconnecting now...")

    connect vpnName
    get state of first configuration where name = vpnName
    repeat until result = "CONNECTED"
        log (vpnName & " is in state [" & result & "]...")
        delay 1
        get state of first configuration where name = vpnName
    end repeat

    log vpnName & " is connected"
end tell
