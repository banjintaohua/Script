#!/usr/bin/bash

# shellcheck disable=SC2046
/usr/libexec/PlistBuddy -c "Set ':values:Markdown Flag:value' $(date +%s) "  /Users/$(whoami)/Library/Containers/net.toolinbox.ipic/Data/Library/SyncedPreferences/net.toolinbox.ipic.plist
sleep 60
nohup /Applications/iPic.app/Contents/MacOS/iPic >> /Users/sea/Documents/Config/Log/iPic.log 2>&1 &
