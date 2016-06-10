tell application "Tunnelblick"
    get state of first configuration where name = (system attribute "PRIMARY_TUNNELBLICK_VPN_NAME")
    copy result to stdout
end tell
