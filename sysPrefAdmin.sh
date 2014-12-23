#!/bin/bash
# https://derflounder.wordpress.com/2014/02/16/managing-the-authorization-database-in-os-x-mavericks/
# CIS 5.7 Require an administrator password to access system-wide preferences

echo Set Preferences...
security authorizationdb read system.preferences > /tmp/system.preferences.plist
sleep 1
defaults write /tmp/system.preferences.plist shared -bool false
sleep 1
sudo security authorizationdb write system.preferences < /tmp/system.preferences.plist
sleep 1
echo Done.