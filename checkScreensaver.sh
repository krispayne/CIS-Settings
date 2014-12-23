#!/bin/bash

# Check screensaver

UUID=`ioreg -rd1 -c IOPlatformExpertDevice | grep "IOPlatformUUID" | sed -e 's/^.*"\(.*\)"$/\1/'`
for i in $(find /Users -type d -maxdepth 1)
	do 
		PREF=$i/Library/Preferences/ByHost/com.apple.screensaver.$UUID 
			if [ -e $PREF.plist ]
				then
					echo -n "Checking User: '$i': "
￼￼￼			defaults read $PREF.plist idleTime 2>&1
			fi
done