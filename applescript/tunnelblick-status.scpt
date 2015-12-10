tell application "Tunnelblick"
    get state of first configuration where name = "s-cloud"
    copy result to stdout
end tell
