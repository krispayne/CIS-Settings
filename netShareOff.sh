#!/bin/bash
# Turn off Internet/File Sharing as part of CIS Benchmark
# These options are all off by defaults and running the launchctl unload on them will begin crippling the system

# 2.4.2 Disable Internet Sharing (Scored)
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.nat NAT -dict Enabled -int 0
sudo launchctl unload -w /System/Library/LaunchDaemons/ com.apple.InternetSharing.plist

# 2.4.8 Disable File Sharing (Scored)
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.AppleFileServer.plist
sudo launchctl unload -w /System/Library/LaunchDaemons/ftp.plist
sudo defaults delete /Library/Preferences/SystemConfiguration/com.apple.smb.server EnabledServices
sudo launchctl unload -w /System/Library/LaunchDaemons/nmbd.plist
sudo launchctl unload -w /System/Library/LaunchDaemons/smbd.plist