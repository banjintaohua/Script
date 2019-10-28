#!/usr/bin/bash

/usr/libexec/PlistBuddy -c "Set ':values:Markdown Flag:value' `date +%s` "  /Users/`whoami`/Library/Containers/net.toolinbox.ipic/Data/Library/SyncedPreferences/net.toolinbox.ipic.plist 
nohup /Applications/iPic.app/Contents/MacOS/iPic >> /var/log/Code/iPic.log 2>&1 &
