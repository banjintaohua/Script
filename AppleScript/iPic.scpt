tell application "Terminal"
	activate
	do script "/usr/libexec/PlistBuddy -c \"Set ':values:Markdown Flag:value' `date +%s` \"  /Users/`whoami`/Library/Containers/net.toolinbox.ipic/Data/Library/SyncedPreferences/net.toolinbox.ipic.plist && nohup /Applications/iPic.app/Contents/MacOS/iPic >> /Users/sea/Documents/Config/Log/iPic.log 2>&1 &"
	delay 0.5
	quit
	tell application "System Events" to Â
    do shell script "kill -9 " & unix id of process "Terminal"
end tell
