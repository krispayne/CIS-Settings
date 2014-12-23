#!/bin/bash
# Turn off Internet/File Sharing as part of CIS Benchmark
# These options are all off by default and running the launchctl unload on them will begin crippling the system

# 2.4.2 Disable Internet Sharing (Scored)
sudo /usr/bin/defaults write /Library/Preferences/SystemConfiguration/com.apple.nat NAT -dict Enabled -int 0
sudo /bin/launchctl unload -w /System/Library/LaunchDaemons/ com.apple.InternetSharing.plist

# 2.4.8 Disable File Sharing (Scored)
sudo /bin/launchctl unload -w /System/Library/LaunchDaemons/com.apple.AppleFileServer.plist
sudo /bin/launchctl unload -w /System/Library/LaunchDaemons/ftp.plist
sudo /usr/bin/defaults delete /Library/Preferences/SystemConfiguration/com.apple.smb.server EnabledServices
sudo /bin/launchctl unload -w /System/Library/LaunchDaemons/nmbd.plist
sudo /bin/launchctl unload -w /System/Library/LaunchDaemons/smbd.plist
