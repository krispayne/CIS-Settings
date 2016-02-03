#!/bin/bash
########################################################################
# CIS Level 1 Benchmark Settings 1.0.0
# El Capitan (10.11)
# Kris Payne
########################################################################

### 1 Install Updates, Patches and Additional Security Software
softwareUpdates() {

    echo 1 Install Updates, Patches and Additional Security Software

    # 1.1 Verify all Apple provided software is current (Scored)
    if [[ "$(/usr/sbin/softwareupdate -l | grep \"No new software available.\")" = "No new software available." ]]; then
        echo Software is up to date
    else
        /usr/sbin/softwareupdate -i -a -v
    fi

    # 1.2 Enable Auto Update
    # Checks to see if computer is polling automatically for updates from Apple

    #if [[ "$(/usr/bin/defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled)" = 1 ]]; then
    #    echo Automatic Update Check already enabled.
    #else
    #    /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -int 1
    #fi

    # SWU managed via policy in Casper

    # 1.3 Enable app update installs
    # Sets Mac App Store auto-update for installed apps.
    
    #if [[ "$(/usr/bin/defaults read /Library/Preferences/com.apple.commerce AutoUpdate)" = "1" ]]; then
    #    echo Auto Update Apps already enabled.
    #else
    #    /usr/bin/defaults write /Library/Preferences/com.apple.storeagent AutoUpdate -bool TRUE
    #fi

    # Policies via AutoPKG and Casper

    # 1.4 Enable system data files and security update installs
    
    #if [[ "$(defaults read /Library/Preferences/com.apple.SoftwareUpdate | grep ConfigDataInstall)" = "ConfigDataInstall = 1;" ]]; then
    #    echo ConfigDataInstall is 1
    #elif [[ "$(defaults read /Library/Preferences/com.apple.SoftwareUpdate | grep CriticalUpdateInstall)" = "CriticalUpdateInstall = 1;" ]]; then
    #    echo ConfigDataInstall is 1
    #else
    #    /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool true
    #    /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool true
    #fi

    # Policy in Casper

    # 1.5 Enable OS X update installs

    #if [[ "$(/usr/bin/defaults read /Library/Preferences/com.apple.commerce AutoUpdateRestartRequired)" = "1" ]]; then
    #    echo OS X is set to auto update
    #else
    #    /usr/bin/defaults write /Library/Preferences/com.apple.commerce AutoUpdateRestartRequired -bool TRUE
    #fi

    # Policy in Casper

}

### 2 System Preferences
systemPreferences() {
    
    echo 2 System Preferences

        echo 2.1 Bluetooth 
        # 2.1 Bluetooth

        # 2.1.1 Turn off Bluetooth, if no paired devices exist (Scored)
        # echo Turn off Bluetooth, if no paired devices exist
        #if [[ "$(/usr/bin/defaults read /Library/Preferences/com.apple.Bluetooth ControllerPowerState)" = "1" ]]; then
        #    echo Bluetooth ControllerPowerState is 1

        #    if [[ "$(system_profiler | grep "Bluetooth:" -A 20 | grep Connectable)" = "Connectable: Yes"]]; then
        #        echo Bluetooth ControllerPowerState is 1 and there are paired devices
        #    elif [[ "$(system_profiler | grep "Bluetooth:" -A 20 | grep Connectable)" = "Connectable: No" ]]; then
        #        echo Bluetooth ControllerPowerState is 1 and there are no paired devices. Turning off Bluetooth.
        #        /usr/bin/defaults write /Library/Preferences/com.apple.Bluetooth ControllerPowerState -int 0
        #    fi

        #elif [[ "$(/usr/bin/defaults read /Library/Preferences/com.apple.Bluetooth ControllerPowerState)" = "0" ]]; then
        #    echo Bluetooth ControllerPowerState is 0
        #else
        #/usr/bin/defaults write /Library/Preferences/com.apple.Bluetooth ControllerPowerState -int 0
        #fi

        # 2.1.2 Turn off Bluetooth "Discoverable" mode when not pairing devices
        # Starting with OS X (10.9) Bluetooth is only set to Discoverable when the Bluetooth System Preference 
        # is selected. To ensure that the computer is not Discoverable do not leave that preference open.

        if [[ "$(/usr/sbin/system_profiler SPBluetoothDataType | grep -i discoverable | awk '{ print $2 }')" = Off ]]; then
            echo Bluetooth Discoverable is off.
        fi

        # uuid=`/usr/sbin/system_profiler SPHardwareDataType | grep "Hardware UUID" | cut -c22-57`
        # /usr/bin/defaults write /Users/$@/Library/Preferences/ByHost/com.apple.Bluetooth.$uuid DiscoverableState -bool no
        # /usr/sbin/chown $@ /Users/$@/Library/Preferences/ByHost/com.apple.Bluetooth.$uuid.plist
        # Stolen from http://krypted.com/mac-security/disabling-bluetooth-discoverable-mode/
        # Need to test.
    
        # 2.1.3 Show Bluetooth status in menu bar (Scored)
        #if [[ $(/usr/bin/defaults read com.apple.systemuiserver menuExtras | grep Bluetooth.menu) = "/System/Library/CoreServices/Menu Extras/Bluetooth.menu"]]; then
        #   echo Bluetooth shown in menu bar
        #else
        #    /usr/bin/defaults write com.apple.systemuiserver menuExtras -array-add "/System/Library/CoreServices/Menu Extras/Bluetooth.menu"
        #fi

        # 2.2 Date & Time
        echo "2.2 Date & Time"
        
        # 2.2.1 Enable "Set time and date automatically" (Scored)
        if [[ "$(/usr/sbin/systemsetup -getusingnetworktime | awk '{ print $3 }')" = "On" ]]; then
            echo NetworkTime already on. Ensuring server is time.apple.com

            if [[ "$(/usr/sbin/systemsetup -getnetworktimeserver | awk '{ print $4 }')" = "time.apple.com" ]]; then
                echo NetworkTime is set and is set to time.apple.com
            fi

        else
            if [[ ! -e /etc/ntp.conf ]]; then
                echo Create /etc/ntp.conf
                /usr/bin/touch /etc/ntp.conf
            fi

            echo Set NetworkTime to time.apple.com
            /usr/sbin/systemsetup -setnetworktimeserver time.apple.com
            echo Ensure it is on
            /usr/sbin/systemsetup -setusingnetworktime on
        
        fi

        # 2.2.2 Ensure time set is within appropriate limits
        /usr/sbin/ntpdate -sv time.apple.com

        # 2.3 Desktop & Screen Saver
        echo "2.3 Desktop & Screen Saver"

        # 2.3.1 Set an inactivity interval of 20 minutes or less for the screen saver
        /usr/bin/defaults -currentHost write com.apple.screensaver idleTime 600
        # going to move this to a user based configuration profile 
    
        # 2.3.2 Secure screen saver corners
        # going to move this to a user based configuration profile 

        # 2.3.3 Verify Display Sleep is set to a value larger than the Screen Saver (Not Scored)
        /usr/bin/pmset -a displaysleep 15
    
        # 2.3.4 Set a screen corner to Start Screen Saver
        #/usr/bin/defaults write ~/Library/Preferences/com.apple.dock wvous-tl-corner 5
    
        # 2.4 Sharing
        echo 2.4 Sharing

        # 2.4.1 Disable Remote Apple Events (Scored)
        if [[ "$(/usr/sbin/systemsetup -getremoteappleevents | awk '{ print $4 }')" = "Off" ]]; then
            echo Remote Apple Events already set to off.
        else
            /usr/sbin/systemsetup -setremoteappleevents off
        fi
    
        # 2.4.2 Disable Internet Sharing (Scored)
        # Internet Sharing is off by default. Running these commands without checking 
        # first will send the machine into a downward sprial of doom and depair.
        # It's your funeral if you uncomment. Left in for remediation/completeness sake.
        # /usr/bin/defaults write /Library/Preferences/SystemConfiguration/com.apple.nat NAT -dict Enabled -int 0
        # /bin/launchctl unload -w /System/Library/LaunchDaemons/ com.apple.InternetSharing.plist

    
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
        # Needs work.
    
        # 2.4.8 Disable File Sharing (Scored)
        # Handled in netShareOff.sh
    
        # 2.4.9 Disable Remote Management (Scored)
        # Used in our environment. Disabling not preferred. Limited to one user, defined in Casper.
    
        # 2.5 Energy Saver
        echo 2.5 Energy Saver

        # 2.5.1 Disable "Wake for network access"
        /usr/bin/pmset -a womp 0 
    
        # 2.5.2 Disable sleeping the computer when connected to power
        /usr/bin/pmset -c sleep 0
    
        # 2.6 Security & Privacy
        echo "2.6 Security & Privacy"

        # 2.6.1 Enable FileVault (Scored)
        # We do not use FileVault in our environment
    
        # 2.6.2 Enable Gatekeeper (Scored)
        /usr/sbin/spctl --master-enable
    
        # 2.6.3 Enable Firewall (Scored)
        /usr/bin/defaults write /Library/Preferences/com.apple.alf globalstate -int 1

        # 2.6.4 Enable Firewall Stealth Mode
        if [[ "$(/usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode)" = "Stealth mode enabled" ]]; then
            echo Firewall Stealth Mode enabled.
        else
            /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
        fi

        # 2.6.5 Review Application Firewall Rules
        # Needs work.
        
        # 2.7 iCloud
        # echo 2.7 iCloud
        # this section is currently only set for Recommendations, not Published standards.

        # 2.8 Pair the remote control infrared receiver if enabled (Scored)
        # Disable:
        /usr/bin/defaults write /Library/Preferences/com.apple.driver.AppleIRController DeviceEnabled 0
    
        # 2.9 Enable Secure Keyboard Entry in terminal.app (Scored)
        /usr/bin/defaults write -app Terminal SecureKeyboardEntry 1
    
        # 2.10 Java 6 is not the default Java runtime
    
        # 2.11 Securely delete files as needed (Recommended)
        # Need to re-work this into either configuration profile or User Template.
        # /usr/bin/defaults write ~/Library/Preferences/com.apple.finder EmptyTrashSecurely 1
}

### 3 Logging and Auditing
loggingAndAuditing() {
    
    echo 3 Logging and Audting

    # Test implementation with SumoLogic: http://www.sumologic.com/applications/mac-osx/

    # 3.1 Configure asl.conf
    echo Configure asl.conf

    # 3.1.1 Retain system.log for 90 or more days (Scored)
    # Contributed by John Oliver on CIS forums
    # https://community.cisecurity.org/collab/public/index.php?path_info=projects%2F28%2Fcomments%2F15292
    /usr/bin/sed -i.bak 's/^>\ system\.log.*/>\ system\.log\ mode=640\ format=bsd\ rotate=seq\ ttl=90/' /etc/asl.conf

    # 3.1.2 Retain appfirewall.log for 90 or more days (Scored)
    # Contributed by John Oliver on CIS forums
    # https://community.cisecurity.org/collab/public/index.php?path_info=projects%2F28%2Fcomments%2F15292
    /usr/bin/sed -i.bak 's/^\?\ \[=\ Facility\ com.apple.alf.logging\]\ .*/\?\ \[=\ Facility\ com.apple.alf.logging\]\ file\ appfirewall.log\ rotate=seq\ ttl=90/' /etc/asl.conf

    # 3.1.3 Retain authd.log for 90 or more days (Scored)
    # Contributed by John Oliver on CIS forums
    # https://community.cisecurity.org/collab/public/index.php?path_info=projects%2F28%2Fcomments%2F15292
    /usr/bin/sed -i.bak 's/^\*\ file\ \/var\/log\/authd\.log.*/\*\ file\ \/var\/log\/authd\.log\ mode=640\ format=bsd\ rotate=seq\ ttl=90/' /etc/asl/com.apple.authd

    # 3.2 Enable security auditing (Scored)
    if [[ "$(/bin/launchctl list | grep -i auditd | awk '{ print $3 }')" = "com.apple.auditd" ]]; then
        echo Auditing enabled
    else
        /bin/launchctl load -w /System/Library/LaunchDaemons/com.apple.auditd.plist
    fi
    
    # 3.3 Configure Security Auditing Flags
    # Contributed by John Oliver on CIS forums
    # https://community.cisecurity.org/collab/public/index.php?path_info=projects%2F28%2Fcomments%2F15292
    /usr/bin/sed -i '' 's/^flags:.*/flags:ad,aa,lo/' /etc/security/audit_control
    /usr/bin/sed -i '' 's/^expire-after:.*/expire-after:90d\ AND\ 1G/' /etc/security/audit_control

    # 3.4 Enable remote logging for Desktops on trusted networks
    # Needs work. Do not have remote logging server setup in my environment to test.

    # 3.5 Retain install.log for 365 or more days
    # Contributed by John Oliver on CIS forums
    # https://community.cisecurity.org/collab/public/index.php?path_info=projects%2F28%2Fcomments%2F15292
    /usr/bin/sed -i.bak 's/^\*\ file\ \/var\/log\/install\.log.*/\*\ file\ \/var\/log\/install\.log\ mode=640\ format=bsd\ rotate=seq\ ttl=365/' /etc/asl/com.apple.install

}

### 4 Network Configurations

####
#### BOOKMARK
####
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
    softwareUpdates
    systemPreferences
    loggingAndAuditing
    networkConfigurations
    systemAccess
    userEnvironment
    additionalConsiderations
    cleanAndReboot
}

# Run mainScript
mainScript
