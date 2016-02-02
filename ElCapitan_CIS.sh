#!/bin/bash
########################################################################
# CIS Level 1 Benchmark Settings beta
# El Capitan (10.11)
# Kris Payne
########################################################################

### 1 Install Updates, Patches and Additional Security Software
softwareUpdates() {

    echo 1 Software Updates

    # 1.1 Verify all application software is current (Scored)
    /usr/sbin/softwareupdate -i -a -v

    # 1.2 Enable Auto Updates
    # /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -int 1  
    # SWU managed via policy in Casper

    # 1.3 Enable App Store auto updte
    # /usr/bin/defaults write /Library/Preferences/com.apple.storeagent AutoUpdate -int 1
    # Policies via AutoPKG and Casper

    # 1.4 Enable system data files and security auto updates
    # /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -int 1
    # /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -int 1
    # Policy in Casper
}

### 2 System Preferences
systemPreferences() {
    
    echo 2 System Preferences

    # 2.1.1 Disable Bluetooth, if no paired devices exist (Scored)
    /usr/bin/defaults write /Library/Preferences/com.apple.Bluetooth ControllerPowerState -int 0

    # 2.1.2 Disable Bluetooth "Discoverable" mode when not pairing devices (Scored)
    # uuid=`/usr/sbin/system_profiler SPHardwareDataType | grep "Hardware UUID" | cut -c22-57`
    # /usr/bin/defaults write /Users/$@/Library/Preferences/ByHost/com.apple.Bluetooth.$uuid DiscoverableState -bool no
    # /usr/sbin/chown $@ /Users/$@/Library/Preferences/ByHost/com.apple.Bluetooth.$uuid.plist
    # Stolen from http://krypted.com/mac-security/disabling-bluetooth-discoverable-mode/
    # Need to test.

    # 2.1.3 Show Bluetooth status in menu bar (Scored)
    /usr/bin/defaults write com.apple.systemuiserver menuExtras -array-add "/System/Library/CoreServices/Menu Extras/Bluetooth.menu"

    # 2.2.1 Enable "Set time and date automatically" (Scored)
    if [ `/usr/sbin/systemsetup -getusingnetworktime | awk '{ print $3 }'` = "On" ]; then
        echo NetworkTime already on. Ensuring server is time.apple.com

        if [ `/usr/sbin/systemsetup -getnetworktimeserver | awk '{ print $4 }'` = "time.apple.com" ]; then
            echo NetworkTime is set and is set to time.apple.com
        fi

    else
        if [ ! -e /etc/ntp.conf ]; then
            echo Create /etc/ntp.conf
            /usr/bin/touch /etc/ntp.conf
        fi

        echo Set NetworkTime to time.apple.com
        /usr/sbin/systemsetup -setnetworktimeserver time.apple.com
        echo Ensure it is on
        /usr/sbin/systemsetup -setusingnetworktime on
        
    fi

    # 2.3.1 Set an inactivity interval of 20 minutes or less for the screen saver (Scored)
    /usr/bin/defaults -currentHost write com.apple.screensaver idleTime 600

    # 2.3.2 Secure screen saver corners

    # 2.3.3 Verify Display Sleep is set to a value larger than the Screen Saver (Not Scored)
    /usr/bin/pmset -a displaysleep 15

    # 2.3.4 Set a screen corner to Start Screen Saver
    #/usr/bin/defaults write ~/Library/Preferences/com.apple.dock wvous-tl-corner 5

    # 2.4.1 Disable Remote Apple Events (Scored)
    if [ `/usr/sbin/systemsetup -getremoteappleevents | awk '{ print $4 }'` = "Off" ]; then
        echo Remote Apple Events already set to off.
    else
        /usr/sbin/systemsetup -setremoteappleevents off
    fi

    # 2.4.2 Disable Internet Sharing (Scored)
    # Handled in netShareOff.sh

    # 2.4.3 Disable Screen Sharing (Scored)
    # Screen sharing controlled by Remote Management Preferences

    # 2.4.4 Disable Printer Sharing (Scored)
    /usr/sbin/cupsctl --no-share-printers

    # 2.4.5 Disable Remote Login (Scored)
    # Controlled at Firewall
    # Also, open only for one user on systems. Defined in Casper

    # 2.4.6 Disable DVD or CD Sharing (Scored)
    # Devices do not have Optical Drives

    # 2.4.7 Disable Bluetooth Sharing

    # 2.4.8 Disable File Sharing (Scored)
    # Handled in netShareOff.sh

    # 2.4.9 Disable Remote Management (Scored)

    # 2.5.1 Disable "Wake for network access"
    /usr/bin/pmset -a womp 0 

    # 2.5.2 Disable sleeping the computer when connected to power
    /usr/bin/pmset -c sleep 0

    # 2.6.1 Enable FileVault (Scored)
    # We do not use FileVault in our environment

    # 2.6.2 Enable Gatekeeper (Scored)
    /usr/sbin/spctl --master-enable

    # 2.6.3 Enable Firewall (Scored)
    /usr/bin/defaults write /Library/Preferences/com.apple.alf globalstate -int 1

    # 2.7 Pair the remote control infrared receiver if enabled (Scored)
    # Disable:
    /usr/bin/defaults write /Library/Preferences/com.apple.driver.AppleIRController DeviceEnabled 0

    # 2.8 Enable Secure Keyboard Entry in terminal.app (Scored)
    /usr/bin/defaults write -app Terminal SecureKeyboardEntry 1

    # 2.9 Java 6 is not the default Java runtime

    # 2.10 Disable Core Dumps
    /bin/launchctl limit core 0

    # 2.11 Configure Secure Empty Trash (Scored) (Level 2)
    /usr/bin/defaults write ~/Library/Preferences/com.apple.finder EmptyTrashSecurely 1
}

### 3 Logging and Auditing
loggingAndAuditing() {
    
    echo 3 Logging and Audting

    # Test implementation with SumoLogic: http://www.sumologic.com/applications/mac-osx/

    # 3.1 Configure asl.conf
    # 3.1.1 Configure Security Auditing Flags
    # Contributed by John Oliver on CIS forums
    # https://community.cisecurity.org/collab/public/index.php?path_info=projects%2F28%2Fcomments%2F15292
    /usr/bin/sed -i '' 's/^flags:.*/flags:ad,aa,lo/' /etc/security/audit_control
    /usr/bin/sed -i '' 's/^expire-after:.*/expire-after:90d\ AND\ 1G/' /etc/security/audit_control

    # 3.1.2 Retain system.log for 90 or more days (Scored)
    # Contributed by John Oliver on CIS forums
    # https://community.cisecurity.org/collab/public/index.php?path_info=projects%2F28%2Fcomments%2F15292
    /usr/bin/sed -i.bak 's/^>\ system\.log.*/>\ system\.log\ mode=640\ format=bsd\ rotate=seq\ ttl=90/' /etc/asl.conf

    # 3.1.3 Retain appfirewall.log for 90 or more days (Scored)
    # Contributed by John Oliver on CIS forums
    # https://community.cisecurity.org/collab/public/index.php?path_info=projects%2F28%2Fcomments%2F15292
    /usr/bin/sed -i.bak 's/^\?\ \[=\ Facility\ com.apple.alf.logging\]\ .*/\?\ \[=\ Facility\ com.apple.alf.logging\]\ file\ appfirewall.log\ rotate=seq\ ttl=90/' /etc/asl.conf

    # 3.1.4 Retain authd.log for 90 or more days (Scored)
    # Contributed by John Oliver on CIS forums
    # https://community.cisecurity.org/collab/public/index.php?path_info=projects%2F28%2Fcomments%2F15292
    /usr/bin/sed -i.bak 's/^\*\ file\ \/var\/log\/authd\.log.*/\*\ file\ \/var\/log\/authd\.log\ mode=640\ format=bsd\ rotate=seq\ ttl=90/' /etc/asl/com.apple.authd

    # 3.2 Enable security auditing (Scored)
    launchctl load -w /System/Library/LaunchDaemons/com.apple.auditd.plist

    # 3.3 Enable remote logging for Desktops on trusted networks
    # test and implement via script

    # 3.4 Configure Security Auditing Flags
    # set in 3.1.1

    # 3.5 Retain install.log for 365 or more days
    # Contributed by John Oliver on CIS forums
    # https://community.cisecurity.org/collab/public/index.php?path_info=projects%2F28%2Fcomments%2F15292
    /usr/bin/sed -i.bak 's/^\*\ file\ \/var\/log\/install\.log.*/\*\ file\ \/var\/log\/install\.log\ mode=640\ format=bsd\ rotate=seq\ ttl=365/' /etc/asl/com.apple.install

}

### 4 Network Configurations
networkConfigurations() {

    echo 4 Network Configurations

    # 4.1 Disable Bonjour advertising service

    # 4.2 Enable "Show Wi-Fi status in menu bar" (Scored)
    # Set via script and policy in Casper

    # 4.3 Create network specific locations

}

### 5 System Access, Authentication and Authorization
systemAccess() {

    echo 5 System Access, Authentication and Authorization
    
    # 5.1 File System Permissions and Access Controls
    
    # 5.1.1 Secure Home Folders (Scored)
    
    # 5.1.2 Repair permissions regularly to ensure binaries and other System files have appropriate permissions (Not Scored)
    # Set via policy in Casper (weekly)
    
    # 5.1.3 Check System Wide Applications for appropriate permissions (Scored)
    # 5.1.4 Check System folder for world writable files (Scored)
    # 5.1.5 Check Library folder for world writable files (Scored)
    # Set via policy in Casper (weekly)
    # Set up and test
    
    # 5.2 Reduce the  timeout period (Scored)
    # listed as issue on github : https://github.com/krispayne/CIS-Settings/issues/2
    
    # 5.3 Automatically lock the login keychain after 15 minutes of inactivity and when sleeping (Scored)
    # Cannot be easily implmented in our environment
    
    # 5.4 Do not enable the "root" account (Scored)
    # Disabled by default
    
    # 5.5 Disable automatic login (Scored)
    /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow.plist autoLoginUser 0
    /usr/bin/defaults delete /Library/Preferences/com.apple.loginwindow.plist autoLoginUser
    
    # 5.6 Require a password to wake the computer from sleep or screen saver (Scored)
    /usr/bin/defaults write com.apple.screensaver askForPassword -int 1
    
    # 5.7 Require an administrator password to access system-wide preferences (Not Scored)
    # Set via script sysPrefAdmin.sh
    
    # 5.8 Disable ability to login to another user's active and locked session (Scored)
    
    # 5.9 Complex passwords must contain an Alphabetic Character (Scored)
    # 5.10 Complex passwords must contain a Numeric Character (Scored)
    # 5.11 Complex passwords must contain a Symbolic Character (Scored)
    # 5.12 Set a minimum password length (Scored)
    # 5.13 Configure account lockout threshold (Scored)
    # Password policy is set via Active Directory
    
    # 5.14 Create an access warning for the login window (Scored)
    /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText "This system is reserved for authorized use only. The use of this system may be monitored."
    
    # 5.15 Do not enter a password-related hint

    # 5.16 Disable Fast User Switching

    # 5.17 Secure individual keychain items

    # 5.18 Create specialized keychains for different purposes

}

###  6 User Accounts and Environment
userEnvironment() {

    echo 6 User Accounts and Environment
    
    # 6.1 Accounts Preferences Action Items
    # 6.1.1 Display login window as name and password (Scored)
    /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool yes
    
    # 6.1.2 Disable "Show password hints" (Scored)
    /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow RetriesUntilHint -int 0
    
    # 6.1.3 Disable guest account login (Scored)
    /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool NO
    
    # 6.1.4 Disable "Allow guests to connect to shared folders" (Scored)
    /usr/bin/defaults write /Library/Preferences/com.apple.AppleFileServer guestAccess -bool no
    /usr/bin/defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server AllowGuestAccess -bool no
    
    # 6.2 Turn on filename extensions (Scored)
    /usr/bin/defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    
    # 6.3 Disable the automatic run of safe files in Safari (Scored)
    /usr/bin/defaults write com.apple.Safari AutoOpenSafeDownloads -boolean no
    
    # 6.4 Use parental controls for systems that are not centrally managed
    # Centrally Managed

}

### 7 Additional Considerations
additionalConsiderations() {

    echo 7 Additional Considerations
    
    # 7.1 iCloud configuration
    # 7.2 Wireless Adapters on Mobile Clients
    # 7.3 iSight Camera Privacy and Confidentiality Concerns
    # 7.4 Computer Name Considerations
    # 7.5 Software Inventory Considerations
    # 7.6 Firewall Consideration
    # 7.7 Automatic Actions for Optical Media
    # 7.8 App Store Automatically download apps purchased on other Macs Considerations
    
    # 7.9 Extensible Firmware Interface (EFI) password
    # Configured in imaging.
}

### The Restarts
cleanAndReboot() {

    echo Finished! Time to restart...
        
    /usr/bin/killall Finder
    /usr/bin/killall SystemUIServer
    /usr/bin/killall -HUP blued
    /sbin/shutdown -r now 
}

mainScript() {

    echo Starting CIS Settings
    
    # RUN AS ROOT

    # comment out sections you do not want to run.
    #softwareUpdates
    systemPreferences
    loggingAndAuditing
    networkConfigurations
    systemAccess
    userEnvironment
    additionalConsiderations
    #cleanAndReboot
}

# Run mainScript
mainScript
