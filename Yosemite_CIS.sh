#!/bin/bash
########################################################################
# CIS Level 1 Benchmark Settings beta
# 10.10
# Kris Payne
########################################################################

echo Starting...

# SUDO UP, MF
sudo -v

# Keep-alive: update existing `sudo` time stamp until `109CIS.sh` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# 1 Install Updates, Patches and Additional Security Software

echo 1 Software Updates
#sleep 3

# Auto update is mandated in Level 1, however we set this in a Casper policy to limit bandwidth during critical hours
# SWU server points to kochcasd1.restorationhardware.com via policy. Updates are then controlled at the server level

# 1.1 Verify all application software is current (Scored)
sudo softwareupdate -i -a -v

# 2 System Preferences
echo 2 System Preferences
#sleep 3

# 2.1.1 Disable Bluetooth, if no paired devices exist (Scored)
# sudo defaults write /Library/Preferences/com.apple.Bluetooth ControllerPowerState -int 0

# 2.1.2 Disable Bluetooth "Discoverable" mode when not pairing devices (Scored)

# 2.1.3 Show Bluetooth status in menu bar (Scored)
# sudo defaults write com.apple.systemuiserver menuExtras -array-add "/System/Library/CoreServices/Menu Extras/Bluetooth.menu"

# 2.2.1 Enable "Set time and date automatically" (Scored)
# sudo systemsetup -setnetworktimeserver time.apple.com
# sudo systemsetup -setusingnetworktime on

# 2.3.1 Set an inactivity interval of 20 minutes or less for the screen saver (Scored)
# Set for 10 minutes in our environment
# defaults -currentHost write com.apple.screensaver idleTime 600

# 2.3.3 Verify Display Sleep is set to a value larger than the Screen Saver (Not Scored)
sudo pmset -a displaysleep 15 sleep 15

# 2.4.1 Disable Remote Apple Events (Scored)
sudo systemsetup -setremoteappleevents off

# 2.4.2 Disable Internet Sharing (Scored)
# Handled in netShareOff.sh

# 2.4.3 Disable Screen Sharing (Scored)
# Screen sharing controlled by Remote Management

# 2.4.4 Disable Printer Sharing (Scored)
cupsctl --no-share-printers

# 2.4.5 Disable Remote Login (Scored)
# Controlled at Firewall

# 2.4.6 Disable DVD or CD Sharing (Scored)

# 2.4.8 Disable File Sharing (Scored)
# Handled in netShareOff.sh

# 2.4.9 Disable Remote Management (Scored)
# Remote Management is used in our environment

# 2.6.1 Enable FileVault (Scored)
# We do not use FileVault in our environment

# 2.6.1 Enable Gatekeeper (Scored)
sudo spctl --master-enable

# 2.6.2 Enable Firewall (Scored)
sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 1

# 2.7 Pair the remote control infrared receiver if enabled (Scored)

# 2.8 Enable Secure Keyboard Entry in terminal.app (Scored)
defaults write -app Terminal SecureKeyboardEntry 1

# 2.11 Configure Secure Empty Trash (Scored) (Level 2)
# defaults write ~/Library/Preferences/com.apple.finder EmptyTrashSecurely 1

# 3 Logging and Auditing
echo 3 Logging and Audting

# 3.1.2 Retain system.log for 90 or more days (Scored)
# 3.1.3 Retain appfirewall.log for 90 or more days (Scored)
# 3.1.4 Retain authd.log for 90 or more days (Scored)
# Set via script

# 3.2 Enable security auditing (Scored)
#sudo launchctl load -w /System/Library/LaunchDaemons/.auditd.plist

# 3.3 Configure Security Auditing Flags (Scored)
# Set via script

# 3.4 Retain install.log for 365 or more days (Scored)
# Set via script

# 4 Network Configurations
echo 4 Network Configurations

# 4.2 Enable "Show Wi-Fi status in menu bar" (Scored)
# Set via script

# 5 System Access, Authentication and Authorization
echo 5 System Access, Authentication and Authorization

# 5.1.1 Secure Home Folders (Scored)
# Set via script: foreach $user sudo chmod -R og-rwx /Users/$user

# 5.1.2 Repair permissions regularly to ensure binaries and other System files have appropriate permissions (Not Scored)
# Set via policy in Casper

# 5.1.3 Check System Wide Applications for appropriate permissions (Scored)

# 5.1.4 Check System folder for world writable files (Scored)

# 5.1.5 Check Library folder for world writable files (Scored)

# 5.2 Reduce the sudo timeout period (Scored)
# Set via script

# 5.3 Automatically lock the login keychain after 15 minutes of inactivity and when sleeping (Scored)

# 5.4 Do not enable the "root" account (Scored)

# 5.5 Disable automatic login (Scored)
#sudo defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser

# 5.6 Require a password to wake the computer from sleep or screen saver (Scored)
# defaults write com.apple.screensaver askForPassword -int 1

# 5.7 Require an administrator password to access system-wide preferences (Not Scored)

# 5.8 Disable ability to login to another user's active and locked session (Scored)

# 5.9 Complex passwords must contain an Alphabetic Character (Scored)
# 5.10 Complex passwords must contain a Numeric Character (Scored)
# 5.11 Complex passwords must contain a Symbolic Character (Scored)
# 5.12 Set a minimum password length (Scored)
# 5.13 Configure account lockout threshold (Scored)
# Password policy is set via Active Directory

# 5.14 Create an access warning for the login window (Scored)
# sudo defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText "This system is reserved for authorized use only. The use of this system may be monitored."

#  6 User Accounts and Environment
echo 6 User Accounts and Environment

# 6.1.1 Display login window as name and password (Scored)
# sudo defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool yes

# 6.1.2 Disable "Show password hints" (Scored)
# sudo defaults write /Library/Preferences/com.apple.loginwindow RetriesUntilHint -int 0

# 6.1.3 Disable guest account login (Scored)
# sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool NO

# 6.1.4 Disable "Allow guests to connect to shared folders" (Scored)
# sudo defaults write /Library/Preferences/com.apple.AppleFileServer guestAccess -bool no
# sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server AllowGuestAccess -bool no

# 6.2 Turn on filename extensions (Scored)
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# 6.3 Disable the automatic run of safe files in Safari (Scored)
defaults write com.apple.Safari AutoOpenSafeDownloads -boolean no

# 7 Additional Considerations

echo Finished! Time to restart...

# The Restarts

sudo killall Finder
sudo killall SystemUIServer
sudo killall -HUP blued
#sudo shutdown -r now